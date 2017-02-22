SmartEvents = require '/imports/collections/smartEvents.coffee'
#Allow multiple modals or the suggested locations list won't show after the
#loading modal is hidden
Modal.allowMultiple = true

Template.smartEvent.onCreated ->
  @editState = new ReactiveVar false
  @eventId = new ReactiveVar()
  @autorun =>
    eventId = Router.current().getParams()._id
    @eventId.set eventId
    @subscribe 'smartEvents', eventId

Template.smartEvent.onRendered ->
  new Clipboard '.copy-link'

Template.smartEvent.helpers
  smartEvent: ->
    SmartEvents.findOne(_id: Template.instance().eventId.get())

  isEditing: ->
    Template.instance().editState.get()

  deleted: ->
    SmartEvents.findOne(_id: Template.instance().eventId.get())?.deleted

Template.smartEvent.events
  'click .edit-link, click #cancel-edit': (event, instance) ->
    instance.editState.set(not instance.editState.get())
