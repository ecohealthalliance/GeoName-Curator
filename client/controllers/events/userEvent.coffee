Incidents = require '/imports/collections/incidentReports.coffee'
#Allow multiple modals or the suggested locations list won't show after the loading modal is hidden
Modal.allowMultiple = true

Template.userEvent.onCreated ->
  @editState = new ReactiveVar false

Template.userEvent.onRendered ->
  new Clipboard '.copy-link'

Template.userEvent.helpers
  isEditing: ->
    Template.instance().editState.get()

  incidentView: ->
    viewParam = Router.current().getParams()._view
    typeof viewParam is 'undefined' or viewParam is 'incidents'

  locationView: ->
    Router.current().getParams()._view is 'locations'

  view: ->
    currentView = Router.current().getParams()._view
    if currentView is 'locations'
      return 'locationList'
    'incidentReports'

  templateData: ->
    Template.instance().data

Template.userEvent.events
  'click .edit-link, click #cancel-edit': (event, template) ->
    template.editState.set(not template.editState.get())
  'click .open-incident-form-in-details': (event, instance) ->
    Modal.show 'suggestedIncidentModal', userEventId: instance.data.userEvent._id
  'click .open-source-form-in-details': (event, instance) ->
    Modal.show 'sourceModal', userEventId: instance.data.userEvent._id
