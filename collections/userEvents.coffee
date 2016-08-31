UserEvents = new Mongo.Collection "userEvents"

@grid ?= {}
@grid.UserEvents = UserEvents

if Meteor.isServer
  ReactiveTable.publish "userEvents", UserEvents, {}

  Meteor.publish "userEvent", (eidID) ->
    UserEvents.find({_id: eidID})

  Meteor.publish "userEvents", () ->
    UserEvents.find()

  UserEvents.allow
    insert: (userID, doc) ->
      doc.creationDate = new Date()
      return Roles.userIsInRole(Meteor.userId(), ['admin'])
    update: (userId, doc, fieldNames, modifier) ->
      return Roles.userIsInRole(Meteor.userId(), ['admin'])

Meteor.methods
  addUserEvent: (name, summary) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      trimmedName = name.trim()
      user = Meteor.user()
      now = new Date()

      if trimmedName.length isnt 0
        UserEvents.insert({
          eventName: trimmedName,
          summary: summary,
          creationDate: now,
          createdByUserId: user._id,
          createdByUserName: user.profile.name,
          lastModifiedDate: now,
          lastModifiedByUserId: user._id,
          lastModifiedByUserName: user.profile.name
          articleCount: 0
        })

  updateUserEvent: (id, name, summary, disease) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      user = Meteor.user()
      grid.UserEvents.update(id, {$set: {
        eventName: name,
        summary: summary,
        disease: disease,
        lastModifiedDate: new Date(),
        lastModifiedByUserId: user._id,
        lastModifiedByUserName: user.profile.name
      }})
  deleteUserEvent: (id) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      UserEvents.remove(id)

  updateUserEventLastModified: (id) ->
    user = Meteor.user()
    if user
      UserEvents.update(id, {$set: {
        lastModifiedDate: new Date(),
        lastModifiedByUserId: user._id,
        lastModifiedByUserName: user.profile.name
      }})
  updateUserEventArticleCount: (id, countModifier) ->
    event = UserEvents.findOne(id)
    UserEvents.update(id, {$set: {articleCount: event.articleCount + countModifier}})

# Add article count field to events
if Meteor.isServer
  Meteor.startup ->
    UserEvents.find({articleCount: {$exists: false}}).forEach (event) ->
      count = grid.Articles.find({userEventId: event._id}).count()
      UserEvents.update(event._id, {$set: {articleCount: count}})
