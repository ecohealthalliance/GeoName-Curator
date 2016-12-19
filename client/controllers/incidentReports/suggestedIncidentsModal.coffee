incidentReportSchema = require('/imports/schemas/incidentReport.coffee')
# A annotation's territory is the sentence containing it,
# and all the following sentences until the next annotation.
# Annotations in the same sentence are grouped.
getTerritories = (annotationsWithOffsets, sents) ->
  # Split annotations with multiple offsets
  # and sort by offset.
  annotationsWithSingleOffsets = []
  annotationsWithOffsets.forEach (annotation)->
    annotation.textOffsets.forEach (textOffset)->
      splitAnnotation = Object.create(annotation)
      splitAnnotation.textOffsets = [textOffset]
      annotationsWithSingleOffsets.push(splitAnnotation)
  annotationsWithOffsets = _.sortBy(annotationsWithSingleOffsets, (annotation)->
    annotation.textOffsets[0][0]
  )
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

# determines if the user should be prompted before leaving the current modal
#
# @param {object} event, the DOM event
# @param {object} instance, the template instance
confirmAbandonChanges = (event, instance) ->
  total = instance.incidentCollection.find().count()
  count = instance.incidentCollection.find(accepted: true).count();
  if count > 0 && instance.hasBeenWarned.get() == false
    event.preventDefault()
    Modal.show 'cancelConfirmationModal',
      modalsToCancel: ['suggestedIncidentsModal', 'cancelConfirmationModal']
      displayName: "Abandon #{count} of #{total} incidents accepted?"
      hasBeenWarned: instance.hasBeenWarned

Template.suggestedIncidentsModal.onCreated ->
  @incidentCollection = new Meteor.Collection(null)
  @hasBeenWarned = new ReactiveVar(false)
  @loading = new ReactiveVar(true)
  @content = new ReactiveVar("")
  Meteor.call("getArticleEnhancements", @data.article, (error, result) =>
    if error
      Modal.hide(@)
      toastr.error error.reason
      return
    locationAnnotations = result.features.filter (f)->f.type == "location"
    datetimeAnnotations = result.features.filter (f)->f.type == "datetime"
    countAnnotations = result.features.filter (f)->f.type == "count"
    geonameIds = locationAnnotations.map((r)->r.geoname.geonameid)
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
      locTerritories = getTerritories(locationAnnotations, sents)
      datetimeAnnotations = datetimeAnnotations
        .map (timeAnnotation)=>
          if not (timeAnnotation.timeRange and
            timeAnnotation.timeRange.begin and
            timeAnnotation.timeRange.end
          )
            return
          # moment parses 0 based month indecies
          if timeAnnotation.timeRange.begin.month
            timeAnnotation.timeRange.begin.month--
          if timeAnnotation.timeRange.end.month
            timeAnnotation.timeRange.end.month--
          timeAnnotation.precision = (
            Object.keys(timeAnnotation.timeRange.end).length +
            Object.keys(timeAnnotation.timeRange.end).length
          )
          timeAnnotation.beginMoment = moment.utc(
            timeAnnotation.timeRange.begin
          )
          # Round up the to day end
          timeAnnotation.endMoment = moment.utc(
            timeAnnotation.timeRange.end
          ).endOf('day')
          publishMoment = moment.utc(@data.article.publishDate)
          if timeAnnotation.beginMoment.isAfter publishMoment, 'day'
            # Omit future dates
            return
          if timeAnnotation.endMoment.isAfter publishMoment, 'day'
            # Truncate ranges that extend into the future
            timeAnnotation.endMoment = publishMoment
          return timeAnnotation
        .filter (x)-> x
      dateTerritories = getTerritories(datetimeAnnotations, sents)
      countAnnotations.forEach((countAnnotation) =>
        [start, end] = countAnnotation.textOffsets[0]
        locationTerritory = _.find locTerritories, ({territoryStart, territoryEnd})->
          if start <= territoryEnd and start >= territoryStart
            return true
        dateTerritory = _.find dateTerritories, ({territoryStart, territoryEnd})->
          if start <= territoryEnd and start >= territoryStart
            return true
        incident =
          locations: locationTerritory.annotations.map(({geoname})->
            geonamesById[geoname.geonameid]
          )
        maxPrecision = 0
        # Use the article's date as the default
        incident.dateRange =
          start: @data.article.publishDate
          end: moment(@data.article.publishDate).add(1, "day")
          type: "day"
        dateTerritory.annotations.forEach (timeAnnotation)->
          if (timeAnnotation.precision > maxPrecision and
            timeAnnotation.beginMoment.isValid() and
            timeAnnotation.endMoment.isValid()
          )
            maxPrecision = timeAnnotation.precision
            incident.dateRange =
              start: timeAnnotation.beginMoment.toDate()
              end: timeAnnotation.endMoment.toDate()
            rangeHours = moment(incident.dateRange.end)
              .diff(incident.dateRange.start, "hours")
            if rangeHours <= 24
              incident.dateRange.type = "day"
            else
              incident.dateRange.type = "precise"
        incident.dateTerritory = dateTerritory
        incident.locationTerritory = locationTerritory
        incident.countAnnotation = countAnnotation
        { count, attributes } = countAnnotation
        if "death" in attributes
          incident.deaths = count
        else
          incident.cases = count
        # Detect whether count is cumulative
        if "incremental" in attributes
          incident.dateRange.cumulative = false
        else if "cumulative" in attributes
          incident.dateRange.cumulative = true
        else if incident.dateRange.type == "day" and count > 300
          incident.dateRange.cumulative = true
        suspectedAttributes = _.intersection([
          "approximate", "average", "suspected"
        ], attributes)
        if suspectedAttributes.length > 0
          incident.suspected = true
        incident.url = [@data.article.url]
        @incidentCollection.insert(incident)
      )
    )
  )

Template.suggestedIncidentsModal.onRendered ->
  $('#sourceModal').on 'hidden.bs.modal', ->
    $('body').addClass('modal-open')

Template.suggestedIncidentsModal.helpers
  incidents: ->
    Template.instance().incidentCollection.find()
  incidentsFound: ->
    Template.instance().incidentCollection.find().count() > 0
  loading: ->
    Template.instance().loading.get()
  annotatedCount: ->
    total = Template.instance().incidentCollection.find().count()
    if total
      count = Template.instance().incidentCollection.find(accepted: true).count()
      "#{count} of #{total} incidents accepted"

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
  'hide.bs.modal #suggestedIncidentsModal': (event, instance) ->
    confirmAbandonChanges(event, instance)

  "click .annotation": (event, instance) ->
    incident = instance.incidentCollection.findOne($(event.target).data("incident-id"))
    content = Template.instance().content.get()
    displayCharacters = 150
    [start, end] = incident.countAnnotation.textOffsets[0]

    startingIndex = Math.min(incident.locationTerritory?.territoryStart or start,
      incident.dateTerritory?.territoryStart or start)
    precedingText = content.slice(startingIndex, start)

    if startingIndex isnt 0
      precedingText = "... " + precedingText

    endingIndex = Math.max(incident.locationTerritory?.territoryEnd or end,
      incident.dateTerritory?.territoryEnd or end)
    followingText = content.slice(end, endingIndex)

    # Split the following text if it contains multiple new lines
    split = followingText.split(/\n{2,}/g)
    if endingIndex isnt (content.length - 1)
      followingText += " ..."

    Modal.show 'suggestedIncidentModal',
      edit: true
      articles: [instance.data.article]
      userEventId: instance.data.userEventId
      incidentCollection: instance.incidentCollection
      incident: incident
      incidentText: Spacebars.SafeString(
        Handlebars._escape(precedingText) +
        "<span class='annotation-text'>" +
        Handlebars._escape(content.slice(start, end)) +
        "</span>" +
        Handlebars._escape(followingText)
      )

  "click #add-suggestions": (event, instance) ->
    incidents = Template.instance().incidentCollection.find(
      accepted: true
    ).map (incident)->
      _.pick(incident, incidentReportSchema.objectKeys())
    Meteor.call "addIncidentReports", incidents, (err, result)->
      if err
        toastr.error err.reason
      else
        Modal.hide(instance)

  "click #non-suggested-incident": (event, instance) ->
    Modal.show "incidentModal",
      articles: [instance.data.article]
      userEventId: instance.data.userEventId
      add: true
      incident:
        url: [instance.data.article.url]
