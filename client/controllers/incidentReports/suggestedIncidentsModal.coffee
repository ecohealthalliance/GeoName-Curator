incidentReportSchema = require('/imports/schemas/incidentReport.coffee')
UserEvents = require '/imports/collections/userEvents.coffee'
Constants = require '/imports/constants.coffee'
{ notify } = require('/imports/ui/notification')
{ stageModals } = require('/imports/ui/modals')
{ annotateContent } = require('/imports/ui/annotation')

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
    .concat(incident.diseaseTerritory?.annotations or [])
    .filter((x)-> x)
  incidentAnnotations = _.sortBy(incidentAnnotations, (annotation)->
    annotation.textOffsets[0][0]
  )
  startingIndex = _.min(incidentAnnotations.map (a)->a.textOffsets[0][0])
  startingIndex = Math.max(startingIndex - 30, 0)
  endingIndex = _.max(incidentAnnotations.map (a)->a.textOffsets[0][1])
  endingIndex = Math.min(endingIndex + 30, content.length - 1)
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
    else if annotation in incident.diseaseTerritory?.annotations
      type = "disease"
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

Template.suggestedIncidentsModal.onRendered ->
  $('#event-source').on 'hidden.bs.modal', ->
    $('body').addClass('modal-open')

  source = @data.article
  Meteor.call 'getArticleEnhancements', source, (error, enhancements) =>
    if error
      Modal.hide(@)
      toastr.error error.reason
      return
    options =
      enhancements: enhancements
      source: source
      acceptByDefault: @data.acceptByDefault
      addToCollection: false
    Meteor.call 'createIncidentReportsFromEnhancements', options, (error, result) =>
      if error
        notify('error', error.reason)
        return
      else
        for incident in result.incidents
          @incidentCollection.insert(incident)
        @loading.set(false)
        @content.set(result.content)

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
    incidents = Template.instance().incidentCollection.find().fetch()
    annotateContent(content, incidents)

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
    instance.$(event.currentTarget).blur()
    incidentCollection = Template.instance().incidentCollection
    incidents = incidentCollection.find(
      accepted: true
    ).map (incident)->
      _.pick(incident, incidentReportSchema.objectKeys())
    count = incidents.length
    if count <= 0
      notify('warning', 'No incidents have been confirmed')
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
        url: instance.data.article.url
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
