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
      return true
    remove: (userID, doc) ->
      return Meteor.user()

Meteor.methods
  addEventCount: (eventId, url, cases, deaths, date) ->
    if url.length
      insertCount = {
        url: url,
        userEventId: eventId
      }
      existingCount = Counts.find(insertCount).fetch()
      if existingCount.length is 0
        user = Meteor.user()
        insertCount.addedByUserId = user._id
        insertCount.addedByUserName = user._id
        insertCount.addedDate = new Date()

        if date.length
          # format of date string is m/d/yyyy
          dateSplit = date.split("/")
          # months are 0 indexed, so subtract 1 when creating the date
          insertCount.date = new Date(dateSplit[2], dateSplit[0] - 1, dateSplit[1])

        newId = Counts.insert(insertCount)

        Meteor.call("updateUserEventLastModified", eventId)

        return newId
  removeCount: (id) ->
    if Meteor.user()
      removed = Counts.findOne(id)
      Counts.remove(id)
      #Meteor.call("removeOrphanedLocations", removed.userEventId, id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
