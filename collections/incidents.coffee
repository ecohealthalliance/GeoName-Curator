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
    Meteor.call("updateUserEventlastIncidentDate", incident.userEventId)
    return newId

  editIncidentReport: (incident) ->
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    res = Incidents.update(incident._id, incident)
    Meteor.call("updateUserEventLastModified", incident.userEventId)
    Meteor.call("updateUserEventlastIncidentDate", incident.userEventId)
    return incident._id

  addIncidentReports: (incidents) ->
    incidents.map (incident)->
      Meteor.call("addIncidentReport", incident)

  removeIncidentReport: (id) ->
    if Meteor.user()
      removed = Incidents.findOne(id)
      Incidents.remove(id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)

if Meteor.isServer
  Meteor.startup ->
    incidents = Incidents.find().fetch()
    for incident in incidents
      # Update incident locations to match location schema
      if incident.locations?.length
        updatedLocations = []
        updatesMade = false
        for loc in incident.locations
          if loc.geonameId
            updatesMade = true
            updatedLocations.push(
              admin1Name: loc.subdivision
              countryName: loc.countryName
              id: loc.geonameId
              latitude: parseFloat(loc.latitude)
              longitude: parseFloat(loc.longitude)
              name: loc.name
            )
          else
            updatedLocations.push(loc)
        if updatesMade
          Incidents.update(incident._id, {$set: {locations: updatedLocations}})
          incident.locations = updatedLocations

      # Split incidents with both case and death counts into separate incidents
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

    # Convert string case and death counts to integers
    incidents = Incidents.find({$or: [{cases: {$type: 2}}, {deaths: {$type: 2}}]}).fetch()
    for incident in incidents
      mongoProjection = false
      if incident.cases
        parsed = parseInt(incident.cases)
        if parsed.toString() is "NaN"
          mongoProjection = {$set: {specify: incident.cases}, $unset: {cases: ""}}
        else
          mongoProjection = {$set: {cases: parsed}}
      else if incident.deaths
        parsed = parseInt(incident.deaths)
        if parsed.toString() is "NaN"
          mongoProjection = {$set: {specify: incident.deaths}, $unset: {deaths: ""}}
        else
          mongoProjection = {$set: {deaths: parsed}}
      if mongoProjection
        Incidents.update({_id: incident._id}, mongoProjection)

    #Convert dates to date ranges
    incidents = Incidents.find({date: {$exists: true}}).fetch()
    for incident in incidents
      startDate = moment(incident.date).set({hour: 0, minute: 0})
      endDate = moment(startDate).set({hour: 23, minute: 59})
      Incidents.update(incident._id, {
        $set: {
          dateRange: {
            start: startDate.toDate()
            end: endDate.toDate()
            type: "day"
          }
        },
        $unset: {
          date: ""
        }
      })
