incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
@Incidents = new Meteor.Collection "counts"
@grid ?= {}
@grid.Incidents = Incidents

getEventIncidentss = (userEventId) ->
  Incidents.find({userEventId: userEventId})

Incidents.getEventIncidentss = getEventIncidentss

if Meteor.isServer
  ReactiveTable.publish "curatorEventIncidents", @Incidents

  Meteor.publish "eventIncidents", (ueId) ->
    getEventIncidentss(ueId)
  Meteor.publish "mapIncidents", () ->
    Incidents.find({locations: {$ne: null}}, {fields: {
      userEventId: 1
      "dateRange.start": 1
      "dateRange.end": 1
      "dateRange.cumulative": 1
      locations: 1
    }})

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
    Meteor.call("updateUserEventLastIncidentDate", incident.userEventId)
    return newId

  editIncidentReport: (incident) ->
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    res = Incidents.update(incident._id, incident)
    Meteor.call("updateUserEventLastModified", incident.userEventId)
    Meteor.call("updateUserEventLastIncidentDate", incident.userEventId)
    return incident._id

  addIncidentReports: (incidents) ->
    incidents.map (incident)->
      Meteor.call("addIncidentReport", incident)

  removeIncidentReport: (id) ->
    if Meteor.user()
      incident = Incidents.findOne(id)
      Incidents.remove(id)
      Meteor.call("updateUserEventLastModified", incident.userEventId)
      Meteor.call("updateUserEventLastIncidentDate", incident.userEventId)

if Meteor.isServer
  Meteor.startup ->
    # Fix empty location arrays, empty string counts and numeric geoname ids.
    incidents = Incidents.find().fetch()
    for incident in incidents
      if incident.locations or incident.locations.length == 0
        Incidents.update(incident._id, {
          $set:
            locations: incident.locations.map((loc)->
              loc.id = "" + loc.id
              loc
            )
        })
      else
        Incidents.update(incident._id, {
          $set:
            locations: [{
              # Earth
              id: "6295630"
              name: "Earth"
              latitude: 0
              longitude: 0
            }]
        })
      if incident.deaths == ""
        Incidents.update(incident._id, {
          $unset:
            deaths: "" 
        })
      if incident.cases == ""
        Incidents.update(incident._id, {
          $unset:
            cases: "" 
        })
    incidents = Incidents.find().fetch()
    for incident in incidents
      try
        incidentReportSchema.validate(incident)
      catch error
        console.log error
        console.log JSON.stringify(incident, 0, 2)
