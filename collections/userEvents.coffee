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
        # Generate the map marker color from a hash of the event name
        hash = 5381
        for i in [0..trimmedName.length - 1]
          hash = ((hash << 5) + hash) + trimmedName.charCodeAt(i)
        r = (hash & 0xFF0000) >> 16
        g = (hash & 0x00FF00) >> 8
        b = hash & 0x0000FF

        UserEvents.insert({
          eventName: trimmedName,
          summary: summary,
          creationDate: now,
          createdByUserId: user._id,
          createdByUserName: user.profile.name,
          lastModifiedDate: now,
          lastModifiedByUserId: user._id,
          lastModifiedByUserName: user.profile.name
          mapColorRGB: r + ", " + g + ", " + b
        })

  updateUserEvent: (id, name, summary) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      user = Meteor.user()
      grid.UserEvents.update(id, {$set: {
        eventName: name,
        summary: summary,
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
