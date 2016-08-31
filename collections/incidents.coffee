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
  addIncidentReport: (incident) ->
    if incident.url.length
      insertIncident = {
        url: [incident.url]
        userEventId: incident.eventId
        species: incident.species
        travelRelated: incident.travel
        status: incident.status
      }

      if incident.locations.length
        insertIncident.locations = incident.locations

      user = Meteor.user()
      insertIncident.addedByUserId = user._id
      insertIncident.addedByUserName = user.profile.name
      insertIncident.addedDate = new Date()

      if incident.date.length
        insertIncident.date = moment(incident.date, "M/D/YYYY").toDate()

      switch incident.type
        when "cases" then insertIncident.cases = incident.value
        when "deaths" then insertIncident.deaths = incident.value
        else insertIncident.specify = incident.value
      newId = Incidents.insert(insertIncident)
      Meteor.call("updateUserEventLastModified", incident.eventId)
      return newId

  removeIncidentReport: (id) ->
    if Meteor.user()
      removed = Incidents.findOne(id)
      Incidents.remove(id)
      #Meteor.call("removeOrphanedLocations", removed.userEventId, id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)

# Split incidents with both case and death counts into separate incidents
if Meteor.isServer
  Meteor.startup ->
    incidents = Incidents.find({$and: [{cases: {$exists: true}}, {deaths: {$exists: true}}]}).fetch()
    for incident in incidents
      if incident.cases?.length and incident.deaths?.length
        newIncident = {
          url: incident.url
          userEventId: incident.userEventId
          species: incident.species
          travelRelated: incident.travel
          addedByUserId: incident.addedByUserId
          addedByUserName: incident.addedByUserName
          addedDate: incident.addedDate
          deaths: incident.deaths
        }

        if incident.locations?.length
          newIncident.locations = incident.locations
        if incident.date
          newIncident.date = incident.date

        Incidents.update(incident._id, {$unset: {deaths: ""}})
        Incidents.insert(newIncident)