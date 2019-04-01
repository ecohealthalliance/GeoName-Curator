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
      studySite: $form.get(0).studySite.checked
      coordinates: $form.get(0).coordinates.checked
      url: @incident.url
  
    for option in $form.find('#incident-location-select2').select2('data')
      item = option.item
      if typeof item.alternateNames is 'string'
        delete item.alternateNames
      incident.locations.push(item)

    incident.accepted = true
    
    if incident.locations.length == 0 and not (incident.ignore or incident.coordinates)
      return notify('error', 'No location specified.')

    if @incident?._id
      incident._id = @incident._id
      incident.addedByUserId = @incident.addedByUserId
      incident.addedByUserName = @incident.addedByUserName
      incident.addedDate = @incident.addedDate
      incident.annotations = @incident.annotations
      incident = _.pick(incident, incidentReportSchema.objectKeys())
      Meteor.call 'editIncidentReport', incident, (error, result) ->
        if not error
          notify('success', 'Incident report updated')
          stageModals(instance, instance.modals)
        else
          notify('error', error.reason)
    else
      incident.annotations = instance?.incident?.annotations
      incident = _.pick(incident, incidentReportSchema.objectKeys())
      Meteor.call 'addIncidentReport', incident, (error, result) ->
        if error
          return notify('error', error)
        notify('success', 'Incident report added.')
        stageModals(instance, instance.modals)

  'click .delete-incident': (event, instance) ->
    incident =
      _id: @incident._id
      accepted: false

    Meteor.call 'updateIncidentReport', incident, (error, result) ->
      if error
        notify('error', 'There was a problem updating your incident reports.')
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
    Modal.hide(instance)
    window.setTimeout =>
      Modal.show 'replaceGeonameModal',
        original: @incident.locations[0]
        updated: incident.locations[0]
    , 1000