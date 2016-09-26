incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'

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
