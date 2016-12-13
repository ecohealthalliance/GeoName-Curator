{ dismissModal } = require '/imports/ui/modals'

Template.createEventModal.events
  'submit #createEvent': (event, instance) ->
    target = event.target
    disease = event.target.eventDisease?.value.trim()
    summary = target.eventSummary?.value.trim()
    eventName = target.eventName
    event.preventDefault()
    valid = eventName.checkValidity()
    unless valid
      toastr.error('Please specify a valid name')
      eventName.focus()
      return
    Meteor.call 'upsertUserEvent', {
      eventName: eventName.value.trim()
      disease: disease
      summary: summary
    }, (error, result) ->
      unless error
        dismissModal '#create-event-modal'
        Router.go 'user-event', _id: result.insertedId
