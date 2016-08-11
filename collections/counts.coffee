Counts = new Meteor.Collection "counts"

@grid ?= {}
@grid.Counts = Counts

getEventCounts = (userEventId) ->
  Counts.find({userEventId: userEventId})

Counts.getEventCounts = getEventCounts

if Meteor.isServer
  Meteor.publish "eventCounts", (ueId) ->
    getEventCounts(ueId)

  Counts.allow
    insert: (userID, doc) ->
      doc.creationDate = new Date()
      return Roles.userIsInRole(Meteor.userId(), ['admin'])
    remove: (userID, doc) ->
      return Roles.userIsInRole(Meteor.userId(), ['admin'])

Meteor.methods
  addEventCount: (eventId, url, locations, cases, deaths, date) ->
    if url.length
      insertCount = {
        url: url,
        userEventId: eventId
      }
      for location in locations
        insertCount.location = location.displayName

      user = Meteor.user()
      insertCount.addedByUserId = user._id
      insertCount.addedByUserName = user.profile.name
      insertCount.addedDate = new Date()

      if date.length
        # format of date string is m/d/yyyy
        dateSplit = date.split("/")
        # months are 0 indexed, so subtract 1 when creating the date
        insertCount.date = new Date(dateSplit[2], dateSplit[0] - 1, dateSplit[1])
      for location in locations
        insertCount.location = location
      insertCount.cases = cases
      insertCount.deaths = deaths
      newId = Counts.insert(insertCount)
      Meteor.call("updateUserEventLastModified", eventId)
      return newId

  removeEventCount: (id) ->
    if Meteor.user()
      removed = Counts.findOne(id)
      Counts.remove(id)
      #Meteor.call("removeOrphanedLocations", removed.userEventId, id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
