@Incidents = new Meteor.Collection "counts"
@grid ?= {}
@grid.Incidents = Incidents

getEventIncidentss = (userEventId) ->
  Incidents.find({userEventId: userEventId})

Incidents.getEventIncidentss = getEventIncidentss

if Meteor.isServer
  Meteor.publish "eventIncidents", (ueId) ->
    getEventIncidentss(ueId)
  Meteor.publish "mapIncidents", () ->
    Incidents.find({locations: {$ne: null}}, {fields: {userEventId: 1, date: 1, locations: 1}})

  Incidents.allow
    insert: (userID, doc) ->
      doc.creationDate = new Date()
      return Roles.userIsInRole(Meteor.userId(), ['admin'])
    remove: (userID, doc) ->
      return Roles.userIsInRole(Meteor.userId(), ['admin'])

Meteor.methods
  addIncidentReport: (eventId, url, locations, type, value, date) ->
    if url.length
      insertIncident = {
        url: [url],
        userEventId: eventId
      }

      if locations.length
        insertIncident.locations = locations

      user = Meteor.user()
      insertIncident.addedByUserId = user._id
      insertIncident.addedByUserName = user.profile.name
      insertIncident.addedDate = new Date()

      if date.length
        insertIncident.date = moment(date, "M/D/YYYY").toDate()

      switch type
        when "cases" then insertIncident.cases = value
        when "deaths" then insertIncident.deaths = value
        else insertIncident.specify = value
      newId = Incidents.insert(insertIncident)
      Meteor.call("updateUserEventLastModified", eventId)
      return newId

  removeIncidentReport: (id) ->
    if Meteor.user()
      removed = Incidents.findOne(id)
      Incidents.remove(id)
      #Meteor.call("removeOrphanedLocations", removed.userEventId, id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
