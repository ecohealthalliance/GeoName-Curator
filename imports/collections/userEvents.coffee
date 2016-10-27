UserEvents = new Mongo.Collection "userEvents"

###
  ensures that a $text index is created on the eventName and summary
###
ensureIndexes = () ->
  UserEvents.rawCollection().createIndex {eventName: 'text', summary: 'text'}, (error) ->
    if error
      console.warn '[UserEvents.createIndex]: ', error

if Meteor.isServer
  Meteor.startup ->
    ensureIndexes()

module.exports = UserEvents
