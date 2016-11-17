{ dismissModal } = require '/imports/ui/modals'

Template.createEventModal.events
  'submit #createEvent': (event, instance) ->
    target = event.target
    eventName = target.eventName
    event.preventDefault()
    valid = eventName.checkValidity()
    unless valid
      toastr.error('Please specify a valid name')
      eventName.focus()
      return
    newEvent = eventName.value
    summary = target.eventSummary.value

    Meteor.call 'editUserEvent', null, newEvent, summary, (error, result) ->
      unless error
        dismissModal '#create-event-modal'
        Router.go 'user-event', _id: result.insertedId
