{ dismissModal } = require '/imports/ui/modals'

Template.createEventModal.onRendered ->
  @$('#create-event-modal').validator()

Template.createEventModal.events
  'submit #createEvent': (event, instance) ->
    return if event.isDefaultPrevented() # Form is invalid
    event.preventDefault()
    target = event.target
    disease = event.target.eventDisease?.value.trim()
    summary = target.eventSummary?.value.trim()
    eventName = target.eventName
    Meteor.call 'upsertUserEvent',
      eventName: eventName.value.trim()
      disease: disease
      summary: summary
    , (error, result) ->
      unless error
        dismissModal('#create-event-modal')
        Router.go 'user-event', _id: result.insertedId
