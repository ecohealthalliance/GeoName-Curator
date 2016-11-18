Feeds = require '/imports/collections/feeds'

Meteor.methods
  addFeed: (feed) ->
    url = feed.url
    user = Meteor.user()
    if Feeds.findOne(url: url)
      return
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error('auth', 'User does not have permission to create incident reports')
    feed.addedByUserId = user._id
    feed.addedByUserName = user.profile.name
    feed.addedDate = new Date()
    Feeds.insert feed
