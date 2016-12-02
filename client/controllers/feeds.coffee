Feeds = require '/imports/collections/feeds.coffee'

Template.feeds.onCreated ->
  @subscribe('feeds')

Template.feeds.helpers
  feeds: Feeds.find()

Template.feeds.events
  'submit .add-feed': (event, instance) ->
    event.preventDefault()
    feedUrl = event.target.feedUrl.value
    if !/^https?:\/\//i.test(feedUrl)
      feedUrl = "http://#{feedUrl}"

    Meteor.call 'addFeed', url: feedUrl, (error, result) ->
      if error
        toastr.warning(error.reason)
      else
        toastr.success "#{feedUrl} has been added"
        event.target.reset()

  'click .delete': (event, instance) ->
    Modal.show 'deleteConfirmationModal',
      objId: @_id
      objNameToDelete: 'feed'
      displayName: @url
