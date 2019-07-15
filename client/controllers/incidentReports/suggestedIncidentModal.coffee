CuratorSources = require '/imports/collections/curatorSources.coffee'
utils = require '/imports/utils.coffee'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
{ notify } = require '/imports/ui/notification'
{ stageModals } = require '/imports/ui/modals'

Template.suggestedIncidentModal.onRendered ->
  instance = @
  Meteor.defer ->
    # Add max-height to snippet if it is taller than form
    formHeight = instance.$('.add-incident--wrapper').height()
    $snippet = $('.snippet--text')
    if $snippet.height() > formHeight
      $snippet.css('max-height', formHeight)

Template.suggestedIncidentModal.onCreated ->
  @incidentCollection = @data.incidentCollection
  @incident = @data.incident or {}
  @incident.suggestedFields = new ReactiveVar(@incident.suggestedFields or [])
  @valid = new ReactiveVar(false)
  @modals =
    currentModal: element: '#suggestedIncidentModal'
    previousModal:
      element: '#suggestedIncidentsModal'
      add: 'fade'

Template.suggestedIncidentModal.onDestroyed ->
  $('#suggestedIncidentModal').off('hide.bs.modal')

Template.suggestedIncidentModal.helpers
  hasSuggestedFields: ->
    Template.instance().incident.suggestedFields.get()

  type: -> [ 'case', 'date', 'location', 'disease' ]

  valid: ->
    Template.instance().valid

  offCanvasStartPosition: ->
    Template.instance().data.offCanvasStartPosition or 'right'

  articleId: ->
    CuratorSources.findOne(_sourceId: Template.instance().incident.url.split('promedmail.org/post/').slice(-1)[0])?._id?._str

Template.suggestedIncidentModal.events
  'hide.bs.modal #suggestedIncidentModal': (event, instance) ->
    if $(event.currentTarget).hasClass('in')
      event.preventDefault()
      stageModals(instance, instance.modals)

  'click .save-modal': (event, instance) ->
    # Submit the form to trigger validation and to update the 'valid'
    # reactiveVar — its value is based on whether the form's hidden submit
    # button's default is prevented
    $('#add-incident').submit()
    return unless instance.valid.get()

    $form = instance.$("form")
  
    incident =
      locations: []
      ignore: $form.get(0).ignore.checked
      researchActivities:
        fieldWork: $form.get(0).fieldWork.checked
        labWork: $form.get(0).labWork.checked
        other: $form.get(0).other.checked
      coordinates: $form.get(0).coordinates.checked
      locationNotFound: $form.get(0).locationNotFound.checked
      url: @incident.url
  
    for option in $form.find('#incident-location-select2').select2('data')
      item = option.item
      if typeof item.alternateNames is 'string'
        delete item.alternateNames
      incident.locations.push(item)

    incident.accepted = true
    
    if incident.locations.length == 0
      if incident.ignore or incident.coordinates or incident.locationNotFound
        if Boolean(incident.coordinates) + Boolean(incident.locationNotFound) > 1
          return notify('error', 'Only one checkbox can be selected.')
      else
        return notify('error', 'No location specified.')
    else if incident.coordinates or incident.locationNotFound
      return notify('error', 'A location cannot be selected when the "coordinates" and "location not found" checkboxes are checked.')

    if @incident?._id
      incident._id = @incident._id
      incident.addedByUserId = @incident.addedByUserId
      incident.addedByUserName = @incident.addedByUserName
      incident.addedDate = @incident.addedDate
      incident.annotations = @incident.annotations
      incident = _.pick(incident, incidentReportSchema.objectKeys())
      Meteor.call 'editIncidentReport', incident, (error, result) ->
        if not error
          notify('success', 'Toponym Mention Updated')
          stageModals(instance, instance.modals)
        else
          notify('error', error.reason)
    else
      incident.annotations = instance?.incident?.annotations
      incident = _.pick(incident, incidentReportSchema.objectKeys())
      Meteor.call 'addIncidentReport', incident, (error, result) ->
        if error
          return notify('error', error)
        notify('success', 'Toponym Mention Added')
        stageModals(instance, instance.modals)

  'click .delete-incident': (event, instance) ->
    incident =
      _id: @incident._id
      accepted: false

    Meteor.call 'updateIncidentReport', incident, (error, result) ->
      if error
        notify('error', 'There was a problem updating your toponym mentions.')
        return
      stageModals(instance, instance.modals)

  'click .update-all': (event, instance) ->
    $('#add-incident').submit()
    return unless instance.valid.get()
    form = instance.$('form')[0]
    $form = $(form)

    incident =
      locations: []
      ignore: form.ignore.checked
      url: @incident.url

    for option in $(form).find('#incident-location-select2').select2('data')
      item = option.item
      if typeof item.alternateNames is 'string'
        delete item.alternateNames
      incident.locations.push(item)

    if incident.locations.length == 0
      return notify('error', 'No location specified.')

    Modal.hide(instance)
    window.setTimeout =>
      Modal.show 'replaceGeonameModal',
        original: @incident.locations[0]
        updated: incident.locations[0]
    , 1000