incidentReportSchema = require('/imports/schemas/incidentReport.coffee')
# A annotation's territory is the sentence containing it,
# and all the following sentences until the next annotation.
# Annotations in the same sentence are grouped.
getTerritories = (annotationsWithOffsets, sents) ->
  annotationIdx = 0
  sentStart = 0
  sentEnd = 0
  territories = []
  sents.forEach (sent) ->
    sentStart = sentEnd
    sentEnd = sentEnd + sent.length
    sentAnnotations = []
    while annotation = annotationsWithOffsets[annotationIdx]
      [aStart, aEnd] = annotation.textOffsets[0]
      if aStart > sentEnd
        break
      else
        sentAnnotations.push annotation
        annotationIdx++
    if sentAnnotations.length > 0 or territories.length == 0
      territories.push
        annotations: sentAnnotations
        territoryStart: sentStart
        territoryEnd: sentEnd
    else
      territories[territories.length - 1].territoryEnd = sentEnd
  return territories

# Parse text into an array of sentences separated by
# periods, colons, semi-colons, or double linebreaks.
parseSents = (text)->
  idx = 0
  sents = []
  sentStart = 0
  while idx < text.length
    char = text[idx]
    if char == "\n"
      [match] = text.slice(idx).match(/^\n+/)
      idx += match.length
      if match.length > 1
        sents[sents.length] = text.slice(sentStart, idx)
        sentStart = idx
    else if /^[\.\;\:]/.test(char)
      idx++
      sents[sents.length] = text.slice(sentStart, idx)
      sentStart = idx
    else
      idx++
  return sents

Template.suggestedIncidentsModal.onCreated ->
  @incidentCollection = new Meteor.Collection(null)
  @loading = new ReactiveVar(true)
  @content = new ReactiveVar("")
  Meteor.call("getArticleEnhancements", @data.article.url, (error, result) =>
    if error
      Modal.hide(@)
      toastr.error error.reason
      return
    geonameIds = result.keypoints
      .filter((k)->k.location)
      .map((k)->k.location.geonameid)
    new Promise((resolve, reject) =>
      if geonameIds.length == 0
        resolve([])
      else
        HTTP.get("https://geoname-lookup.eha.io/api/geonames", {
          params:
            ids: geonameIds
        }, (error, geonamesResult) =>
          if error
            toastr.error error.reason
            Modal.hide(@)
            reject()
          else
            resolve(geonamesResult.data.docs)
        )
    ).then((locations) =>
      geonamesById = {}
      locations.forEach (loc)->
        geonamesById[loc.id] =
          id: loc.id
          name: loc.name
          admin1Name: loc.admin1Name
          admin2Name: loc.admin2Name
          latitude: parseFloat(loc.latitude)
          longitude: parseFloat(loc.longitude)
          countryName: loc.countryName
          population: loc.population
          featureClass: loc.featureClass
          featureCode: loc.featureCode
          alternateNames: loc.alternateNames
      @loading.set(false)
      @content.set result.source.cleanContent.content
      sents = parseSents(result.source.cleanContent.content)
      keypoints = result.keypoints
      locTerritories = getTerritories(keypoints.filter((keypoint)->keypoint.location), sents)
      dateTerritories = getTerritories(keypoints.filter((keypoint)->keypoint.time), sents)
      result.keypoints.forEach((keypoint) =>
        unless keypoint.count then return
        [kStart, kEnd] = keypoint.textOffsets[0]
        locationTerritory = _.find locTerritories, ({territoryStart, territoryEnd})->
          if kStart <= territoryEnd and kStart >= territoryStart
            return true
        dateTerritory = _.find dateTerritories, ({territoryStart, territoryEnd})->
          if kStart <= territoryEnd and kStart >= territoryStart
            return true
        incident =
          locations: locationTerritory.annotations.map(({location})->geonamesById[location.geonameid])
        mostFromKeys = 0
        mostToKeys = 0
        dateTerritory.annotations.forEach (annotation)->
          time = annotation.time
          if not time.timeRange
            #console.log "No Timerange", annotation
            return
          incident.dateRange = {}
          fromTime = _.clone(time.timeRange.begin)
          if fromTime
            fromKeys = Object.keys(fromTime).length
            # moment parses 0 based month indecies
            if fromTime.month then fromTime.month--
            parsedDate = moment(fromTime)
            if fromKeys > mostFromKeys and parsedDate.isValid()
              incident.dateRange.start = parsedDate.toDate()
              mostFromKeys = fromKeys
          else
            console.log "No fromTime", annotation
          toTime = _.clone(time.timeRange.end)
          if toTime
            toKeys = Object.keys(toTime).length
            # moment parses 0 based month indecies
            if toTime.month then toTime.month--
            # Round up the to date
            parsedDate = moment(_.extend({hours:23, minutes: 59}, toTime))
            if toKeys > mostToKeys and parsedDate.isValid()
              incident.dateRange.end = parsedDate.toDate()
              mostToKeys = toKeys
          else
            console.log "No toTime", annotation
          if moment(incident.dateRange.end).diff(incident.dateRange.start, "hours") <= 24
            incident.dateRange.type = "day"
          else
            incident.dateRange.type = "precise"
        incident.dateTerritory = dateTerritory
        incident.locationTerritory = locationTerritory
        incident.countAnnotation = keypoint
        if keypoint.count.case
          incident.cases = keypoint.count.number
        else if keypoint.count.death
          incident.deaths = keypoint.count.number
        incident.url = [@data.article.url]
        @incidentCollection.insert(incident)
      )
    )
  )
Template.suggestedIncidentsModal.helpers
  incidents: ->
    Template.instance().incidentCollection.find()
  incidentsFound: ->
    Template.instance().incidentCollection.find().count() > 0
  loading: ->
    Template.instance().loading.get()
  annotatedContent: ->
    content = Template.instance().content.get()
    lastEnd = 0
    html = ""
    Template.instance().incidentCollection.find().map (incident)->
      [start, end] = incident.countAnnotation.textOffsets[0]
      html += (
        Handlebars._escape("#{content.slice(lastEnd, start)}") +
        """<span
          class='annotation annotation-text#{if incident.accepted then " accepted" else ""}'
          data-incident-id='#{incident._id}'
        >#{Handlebars._escape(content.slice(start, end))}</span>"""
      )
      lastEnd = end
    html += Handlebars._escape("#{content.slice(lastEnd)}")
    new Spacebars.SafeString(html)

Template.suggestedIncidentsModal.events
  "click .annotation": (event, template) ->
    incident = template.incidentCollection.findOne($(event.target).data("incident-id"))
    content = Template.instance().content.get()
    displayCharacters = 150
    [start, end] = incident.countAnnotation.textOffsets[0]

    startingIndex = start - displayCharacters
    if startingIndex < 0
      startingIndex = 0
    # The text before the incident link
    precedingText = content.slice(startingIndex, start)

    # Split the preceding text if it contains multiple new lines
    split = precedingText.split(/\n{2,}/g)
    if split.length > 1
      precedingText = split[split.length - 1]
    else if startingIndex isnt 0
      precedingText = "... " + precedingText

    endingIndex = end + displayCharacters
    if endingIndex >= content.length
      endingIndex = content.length - 1
    followingText = content.slice(end, endingIndex)

    # Split the following text if it contains multiple new lines
    split = followingText.split(/\n{2,}/g)
    if split.length > 1
      followingText = split[0]
    else if endingIndex isnt (content.length - 1)
      followingText += " ..."

    Modal.show("suggestedIncidentModal", {
      articles: [template.data.article]
      userEventId: template.data.userEventId
      incidentCollection: template.incidentCollection
      incident: incident
      incidentText: Spacebars.SafeString(Handlebars._escape(precedingText) + """<span class='annotation-text'>#{Handlebars._escape(content.slice(start, end))}</span>""" + Handlebars._escape(followingText))
    })
  "click #add-suggestions": (event, template) ->
    incidents = Template.instance().incidentCollection.find({accepted: true}).map (incident)->
      _.pick(incident, incidentReportSchema.objectKeys())
    Meteor.call "addIncidentReports", incidents, (err, result)->
      if err
        toastr.error err.reason
      else
        Modal.hide(template)
  "click #non-suggested-incident": (event, template) ->
    Modal.show("incidentModal", {
      articles: [template.data.article]
      userEventId: template.data.userEventId
      add: true
      incident: {url: [template.data.article.url]}
    })
