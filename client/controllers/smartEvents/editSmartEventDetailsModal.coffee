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
    form = event.target
    return if event.isDefaultPrevented() # Form is invalid
    event.preventDefault()
    calendar = instance.calendar
    smartEvent =
      _id: @_id
      eventName: form.eventName.value.trim()
      summary: form.eventSummary.value.trim()
      disease: form.eventDisease.value.trim()
      dateRange:
        start: calendar.startDate.toDate()
        end: calendar.endDate.toDate()
    Meteor.call 'upsertSmartEvent', smartEvent, (error, {insertedId}) ->
      if error
        notify('error', error.message)
      else
        notify('success', 'Smart event added')
        dismissModal(instance.$('#smart-event-modal')).then ->
          if instance.data.action == 'add'
            Router.go('smart-event', _id: insertedId)

  'click .delete-event': (event, instance) ->
    instance.confirmingDeletion.set true

  'click .back-to-editing': (event, instance) ->
    instance.confirmingDeletion.set false
