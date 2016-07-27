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
  addUserEvent: (name, locations) ->
    trimmedName = name.trim()
    if trimmedName.length isnt 0
      UserEvents.insert({eventName: trimmedName, creationDate: new Date()}, (error, result) ->
        if result
          Meteor.call("addEventLocations", result, locations)
      )
