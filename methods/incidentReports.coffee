incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
Constants = require '/imports/constants.coffee'

Meteor.methods
  addIncidentReport: (incident) ->
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin', 'curator'])
      throw new Meteor.Error("auth", "User does not have permission to create incident reports")
    incident.addedByUserId = user._id
    incident.addedByUserName = user.profile.name
    incident.addedDate = new Date()
    newId = Incidents.insert(incident)
    return newId

  # similar to editIncidentReport, but allows you to set a single field without changing any other existing fields.
  updateIncidentReport: (incident) ->
    _id = incident._id
    delete incident._id
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin', 'curator'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    incident.modifiedByUserId = user._id
    incident.modifiedByUserName = user.profile.name
    incident.modifiedDate = new Date()
    res = Incidents.update({_id: _id}, {$set: incident})
    return incident._id

  editIncidentReport: (incident) ->
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin', 'curator'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    incident.modifiedByUserId = user._id
    incident.modifiedByUserName = user.profile.name
    incident.modifiedDate = new Date()
    res = Incidents.update(incident._id, incident)
    return incident._id

  addIncidentReports: (incidents) ->
    incidents.map (incident)->
      Meteor.call("addIncidentReport", incident)

  removeIncidentReport: (id) ->
    if not Roles.userIsInRole(@userId, ['admin', 'curator'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    incident = Incidents.findOne(id)
    user = Meteor.user()
    Incidents.update id,
      $set:
        deleted: true,
        deletedDate: new Date()
        modifiedByUserId: user._id
        modifiedByUserName: user.profile.name
        modifiedDate: new Date()

  addIncidentsToEvent: (incidentIds, userEventId) ->
    Incidents.update _id: $in: incidentIds,
      $set: userEventId: userEventId
      {multi: true}
