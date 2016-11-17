Feeds = require '/imports/collections/feeds.coffee'

Template.feeds.onCreated ->
  Meteor.subscribe 'feeds'

Template.feeds.helpers
  feeds: Feeds.find()

Template.feeds.events
  'submit .add-feed': (event, instance) ->
    event.preventDefault()
    feedUrl = event.target.feedUrl.value
    if !/^(f|ht)tps?:\/\//i.test(feedUrl)
      feedUrl = "http://#{feedUrl}"

    Meteor.call 'addFeed', url: feedUrl, (error, result) ->
      unless error
        toastr.success "#{feedUrl} has been added"
        event.target.reset()
