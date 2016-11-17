Feeds = require '/imports/collections/feeds'

Meteor.methods
  addFeed: (feed) ->
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to create incident reports")
    feed.addedByUserId = user._id
    feed.addedByUserName = user.profile.name
    feed.addedDate = new Date()
    Feeds.insert feed
