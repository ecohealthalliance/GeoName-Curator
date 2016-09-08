incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
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
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to create incident reports")
    incident.addedByUserId = user._id
    incident.addedByUserName = user.profile.name
    incident.addedDate = new Date()
    newId = Incidents.insert(incident)
    Meteor.call("updateUserEventLastModified", incident.userEventId)
    return newId

  editIncidentReport: (incident) ->
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    res = Incidents.update(incident._id, incident)
    Meteor.call("updateUserEventLastModified", incident.userEventId)
    return incident._id

  addIncidentReports: (incidents) ->
    incidents.map (incident)->
      Meteor.call("addIncidentReport", incident)

  removeIncidentReport: (id) ->
    if Meteor.user()
      removed = Incidents.findOne(id)
      Incidents.remove(id)
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
