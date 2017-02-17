incidentReportSchema = require('/imports/schemas/incidentReport.coffee')
UserEvents = require '/imports/collections/userEvents.coffee'
Constants = require '/imports/constants.coffee'
{ notify } = require('/imports/ui/notification')
{ stageModals } = require('/imports/ui/modals')

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
    if char == '\n'
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
  if sentStart < idx
    sents[sents.length] = text.slice(sentStart, idx)
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
    false
  else
    true

showSuggestedIncidentModal = (event, instance)->
  incident = instance.incidentCollection.findOne($(event.target).data("incident-id"))
  content = Template.instance().content.get()
  displayCharacters = 150
  incidentAnnotations = [incident.countAnnotation]
    .concat(incident.dateTerritory?.annotations or [])
    .concat(incident.locationTerritory?.annotations or [])
    .filter((x)-> x)
  incidentAnnotations = _.sortBy(incidentAnnotations, (annotation)->
    annotation.textOffsets[0][0]
  )
  [countStart, countEnd] = incident.countAnnotation.textOffsets[0]
  startingIndex = Math.min(incident.locationTerritory?.territoryStart or countStart,
    incident.dateTerritory?.territoryStart or countStart)
  endingIndex = Math.max(incident.locationTerritory?.territoryEnd or countEnd,
    incident.dateTerritory?.territoryEnd or countEnd)
  lastEnd = startingIndex
  html = ""
  if incidentAnnotations[0]?.textOffsets[0][0] isnt 0
    html += "..."
  incidentAnnotations.map (annotation)->
    [start, end] = annotation.textOffsets[0]
    type = "case"
    if annotation in incident.dateTerritory?.annotations
      type = "date"
    else if annotation in incident.locationTerritory?.annotations
      type = "location"
    html += (
      Handlebars._escape("#{content.slice(lastEnd, start)}") +
      """<span class='annotation-text #{type}'>#{
        Handlebars._escape(content.slice(start, end))
      }</span>"""
    )
    lastEnd = end
  html += Handlebars._escape("#{content.slice(lastEnd, endingIndex)}")
  if lastEnd < content.length - 1
    html += "..."
  Modal.show 'suggestedIncidentModal',
    edit: true
    articles: [instance.data.article]
    userEventId: instance.data.userEventId
    incidentCollection: instance.incidentCollection
    incident: incident
    incidentText: Spacebars.SafeString(html)

modalClasses = (modal, add, remove) ->
  modal.currentModal.add = add
  modal.currentModal.remove = remove
  modal

dismissModal = (instance) ->
  modal = modalClasses(instance.modal, 'off-canvas--top', 'staged-left')
  stageModals(instance, modal)

sendModalOffStage = (instance) ->
  modal = modalClasses(instance.modal, 'staged-left', 'off-canvas--right fade')
  stageModals(instance, modal, false)

Template.suggestedIncidentsModal.onCreated ->
  @incidentCollection = new Meteor.Collection(null)
  @hasBeenWarned = new ReactiveVar(false)
  @loading = new ReactiveVar(true)
  @content = new ReactiveVar('')
  @annotatedContentVisible = new ReactiveVar(true)
  @modal =
    currentModal:
      element: '#suggestedIncidentsModal'

  Meteor.call('getArticleEnhancements', @data.article, (error, result) =>
    if error
      Modal.hide(@)
      toastr.error error.reason
      return
    locationAnnotations = result.features.filter (f) -> f.type == 'location'
    datetimeAnnotations = result.features.filter (f) -> f.type == 'datetime'
    countAnnotations = result.features.filter (f) -> f.type == 'count'
    geonameIds = locationAnnotations.map((r) -> r.geoname.geonameid)
    # Query geoname lookup service to get admin names.
    # The GRITS api reponse only includes admin codes.
    new Promise((resolve, reject) =>
      if geonameIds.length == 0
        resolve([])
      else
        HTTP.get(Constants.GRITS_URL + '/api/geoname_lookup/api/geonames', {
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
      locations.forEach (loc) ->
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
        .map (timeAnnotation) =>
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
        .filter (x) -> x
      dateTerritories = getTerritories(datetimeAnnotations, sents)
      countAnnotations.forEach((countAnnotation) =>
        [start, end] = countAnnotation.textOffsets[0]
        locationTerritory = _.find locTerritories, ({territoryStart, territoryEnd}) ->
          if start <= territoryEnd and start >= territoryStart
            return true
        dateTerritory = _.find dateTerritories, ({territoryStart, territoryEnd}) ->
          if start <= territoryEnd and start >= territoryStart
            return true
        incident =
          locations: locationTerritory.annotations.map(({geoname}) ->
            geonamesById[geoname.geonameid]
          )
        maxPrecision = 0
        # Use the article's date as the default
        incident.dateRange =
          start: @data.article.publishDate
          end: moment(@data.article.publishDate).add(1, 'day')
          type: 'day'
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
              .diff(incident.dateRange.start, 'hours')
            if rangeHours <= 24
              incident.dateRange.type = 'day'
            else
              incident.dateRange.type = 'precise'
        incident.dateTerritory = dateTerritory
        incident.locationTerritory = locationTerritory
        incident.countAnnotation = countAnnotation
        { count, attributes } = countAnnotation
        if 'death' in attributes
          incident.deaths = count
        else if "case" in attributes or "hospitalization" in attributes
          incident.cases = count
        else
          incident.cases = count
          incident.uncertainCountType = true
        if @data.acceptByDefault and not incident.uncertainCountType
          incident.accepted = true
        # Detect whether count is cumulative
        if 'incremental' in attributes
          incident.dateRange.cumulative = false
        else if 'cumulative' in attributes
          incident.dateRange.cumulative = true
        else if incident.dateRange.type == 'day' and count > 300
          incident.dateRange.cumulative = true
        suspectedAttributes = _.intersection([
          'approximate', 'average', 'suspected'
        ], attributes)
        if suspectedAttributes.length > 0
          incident.status = 'suspected'
        incident.url = [@data.article.url]
        event = UserEvents.findOne(@data.article?.userEventId)
        if event?.disease
          incident.disease = event.disease
        incident.suggestedFields = _.intersection(
          Object.keys(incident),
          [
            'disease'
            'cases'
            'deaths'
            'dateRange'
            'status'
            if incident.locations.length then 'locations'
          ]
        )
        if incident.dateRange?.cumulative
          incident.suggestedFields.push('cumulative')
        @incidentCollection.insert(incident)
      )
    )
  )

Template.suggestedIncidentsModal.onRendered ->
  instance = @
  $('#event-source').on 'hidden.bs.modal', ->
    $('body').addClass('modal-open')

Template.suggestedIncidentsModal.onDestroyed ->
  $('#suggestedIncidentsModal').off('hide.bs.modal')

Template.suggestedIncidentsModal.helpers
  showTable: ->
    Template.instance().data.showTable

  incidents: ->
    Template.instance().incidentCollection.find
      accepted: true
      specify: $exists: false

  incidentsFound: ->
    Template.instance().incidentCollection.find().count() > 0

  isLoading: ->
    Template.instance().loading.get()

  annotatedCount: ->
    total = Template.instance().incidentCollection.find().count()
    if total
      count = Template.instance().incidentCollection.find(accepted: true).count()
      "#{count} of #{total} incidents accepted"

  annotatedContent: ->
    content = Template.instance().content.get()
    lastEnd = 0
    html = ''
    Template.instance().incidentCollection.find().map (incident)->
      [start, end] = incident.countAnnotation.textOffsets[0]
      html += (
        Handlebars._escape("#{content.slice(lastEnd, start)}") +
        """<span
          class='annotation annotation-text#{
            if incident.accepted then " accepted" else ""
          }#{
            if incident.uncertainCountType then " uncertain" else ""
          }'
          data-incident-id='#{incident._id}'
        >#{Handlebars._escape(content.slice(start, end))}</span>"""
      )
      lastEnd = end
    html += Handlebars._escape("#{content.slice(lastEnd)}")
    new Spacebars.SafeString(html)

  annotatedContentVisible: ->
    Template.instance().annotatedContentVisible.get()

  tableVisible: ->
    not Template.instance().annotatedContentVisible.get()

  incidentProperties: ->
    properties = []
    if @travelRelated
      properties.push "Travel Related"
    if @dateRange?.cumulative
      properties.push "Cumulative"
    if @approximate
      properties.push "Approximate"
    properties.join(";")


Template.suggestedIncidentsModal.events
  'hide.bs.modal #suggestedIncidentsModal': (event, instance) ->
    proceed = confirmAbandonChanges(event, instance)
    if proceed and $(event.currentTarget).hasClass('in')
      dismissModal(instance)
      event.preventDefault()

  'click .annotation': (event, instance) ->
    sendModalOffStage(instance)
    showSuggestedIncidentModal(event, instance)

  'click #add-suggestions': (event, instance) ->
    incidentCollection = Template.instance().incidentCollection
    incidents = incidentCollection.find(
      accepted: true
    ).map (incident)->
      _.pick(incident, incidentReportSchema.objectKeys())
    count = incidents.length
    if count <= 0
      toastr.warning 'No incidents have been confirmed'
      return
    Meteor.call 'addIncidentReports', incidents, (err, result)->
      if err
        toastr.error err.reason
      else
        # we need to allow the modal to close without warning confirmAbandonChanges
        # since the incidents have been saved to the remote, it makes sense to
        # empty our collection temporary work.
        incidentCollection.remove({})
        # hide the modal
        notify('success', 'Incident Reports Added')
        dismissModal(instance)

  'click #non-suggested-incident': (event, instance) ->
    sendModalOffStage(instance)
    Modal.show 'incidentModal',
      articles: [instance.data.article]
      userEventId: instance.data.userEventId
      add: true
      incident:
        url: [instance.data.article.url]
      offCanvas: 'right'

  'click #save-csv': (event, instance) ->
    fileType = $(event.currentTarget).attr('data-type')
    table = instance.$('table.incident-table')
    if table.length
      table.tableExport(type: fileType)

  'click .count': (event, instance) ->
    showSuggestedIncidentModal(event, instance)

  'click .annotated-content': (event, instance) ->
    instance.annotatedContentVisible.set true

  'click .incident-table': (event, instance) ->
    instance.annotatedContentVisible.set false
