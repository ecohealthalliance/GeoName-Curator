@Counts = new Meteor.Collection "counts"
@grid ?= {}
@grid.Counts = Counts

getEventCounts = (userEventId) ->
  Counts.find({userEventId: userEventId})

Counts.getEventCounts = getEventCounts

if Meteor.isServer
  Meteor.publish "eventCounts", (ueId) ->
    getEventCounts(ueId)
  Meteor.publish "mapIncidents", () ->
    Counts.find({locations: {$ne: null}}, {fields: {userEventId: 1, date: 1, locations: 1}})

  Counts.allow
    insert: (userID, doc) ->
      doc.creationDate = new Date()
      return Roles.userIsInRole(Meteor.userId(), ['admin'])
    remove: (userID, doc) ->
      return Roles.userIsInRole(Meteor.userId(), ['admin'])

Meteor.methods
  addIncidentReport: (incident) ->
    if incident.url.length
      insertCount = {
        url: [incident.url]
        userEventId: incident.eventId
        species: incident.species
        travelRelated: incident.travel
      }

      if incident.locations.length
        insertCount.locations = incident.locations

      user = Meteor.user()
      insertCount.addedByUserId = user._id
      insertCount.addedByUserName = user.profile.name
      insertCount.addedDate = new Date()

      if incident.date.length
        insertCount.date = moment(incident.date, "M/D/YYYY").toDate()

      switch incident.type
        when "cases" then insertCount.cases = incident.value
        when "deaths" then insertCount.deaths = incident.value
        else insertCount.specify = incident.value
      newId = Counts.insert(insertCount)
      Meteor.call("updateUserEventLastModified", incident.eventId)
      return newId

  removeEventCount: (id) ->
    if Meteor.user()
      removed = Counts.findOne(id)
      Counts.remove(id)
      #Meteor.call("removeOrphanedLocations", removed.userEventId, id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
