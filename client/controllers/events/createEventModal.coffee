CuratorSources = require '/imports/collections/curatorSources.coffee'
{ dismissModal } = require '/imports/ui/modals'

Template.createEventModal.onRendered ->
  Meteor.defer ->
    @$('#createEvent').validator
      # Do not disable inputs since we don't in other areas of the app
      disable: false

Template.createEventModal.events
  'submit #createEvent': (event, instance) ->
    return if event.isDefaultPrevented() # Form is invalid
    event.preventDefault()
    target = event.target
    disease = event.target.eventDisease?.value.trim()
    summary = target.eventSummary?.value.trim()
    eventName = target.eventName
    sourceId = instance.data?.sourceId
    if sourceId
      source = CuratorSources.findOne(sourceId)
    Meteor.call 'upsertUserEvent',
      eventName: eventName.value.trim()
      disease: disease
      summary: summary
      displayOnPromed: event.target.promed.checked
    , (error, result) ->
      unless error
        dismissModal('#create-event-modal')
        if source
          Meteor.call 'addEventSource',
            url: "promedmail.org/post/#{source._sourceId}"
            userEventId: result.insertedId
            title: source.title
            publishDate: source.publishDate
            publishDateTZ: "EST"
        else
          Router.go('user-event', _id: result.insertedId)
