UserEvents = new Mongo.Collection "userEvents"
UserEvents.allow
  insert: (userID, doc) ->
    doc.creationDate = new Date()
    Roles.userIsInRole(Meteor.userId(), ['admin'])
  update: (userId, doc, fieldNames, modifier) ->
    Roles.userIsInRole(Meteor.userId(), ['admin'])
module.exports = UserEvents
