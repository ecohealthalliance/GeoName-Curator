{ dismissModal } = require '/imports/ui/modals'
{ notify } = require '/imports/ui/notification'
createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker'
require 'bootstrap-validator'

Template.editSmartEventDetailsModal.onCreated ->
  @confirmingDeletion = new ReactiveVar false

Template.editSmartEventDetailsModal.onRendered ->
  Meteor.defer =>
    @$('#editEvent').validator
      # Do not disable inputs since we don't in other areas of the app
      disable: false
    createInlineDateRangePicker $("#date-picker")
    @calendar = $('#date-picker').data('daterangepicker')

Template.editSmartEventDetailsModal.helpers
  confirmingDeletion: ->
    Template.instance().confirmingDeletion.get()

  adding: ->
    Template.instance().data?.action is 'add'

Template.editSmartEventDetailsModal.events
  'submit #editEvent': (event, instance) ->
    return if event.isDefaultPrevented() # Form is invalid
    event.preventDefault()
    name = event.target.eventName.value.trim()
    disease = event.target.eventDisease.value.trim()
    summary = event.target.eventSummary.value.trim()
    Meteor.call 'upsertSmartEvent',
      _id: @_id
      eventName: name
      summary: summary
      disease: disease
    , (error, {insertedId}) ->
      if error
        toastr.error error.message
        return
      else
        notify('success', 'Smart event added')
        dismissModal(instance.$('#smart-event-modal')).then ->
          if instance.data.action == 'add'
            Router.go('smart-event', _id: insertedId)

  'click .delete-event': (event, instance) ->
    instance.confirmingDeletion.set true

  'click .back-to-editing': (event, instance) ->
    instance.confirmingDeletion.set false
