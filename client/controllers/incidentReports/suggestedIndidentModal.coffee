utils = require '/imports/utils.coffee'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'

Template.suggestedIncidentModal.onCreated ->
  @incidentCollection = @data.incidentCollection
  @incident = @data.incident
  @incidentFormDetails =
    incidentStatus: new ReactiveVar(null)
    incidentType: new ReactiveVar(null)
    cumulative: new ReactiveVar(false)
    travelRelated: new ReactiveVar(false)

Template.suggestedIncidentModal.helpers
  incidentFormDetails: ->
    Template.instance().incidentFormDetails

Template.suggestedIncidentModal.events
  'click .reject': (event, instance) ->
    Template.instance().incidentCollection.update instance.incident._id,
      $set:
        accepted: false

  'click .save-modal': (event, instance) ->
    incident = utils.incidentReportFormToIncident instance.$("form")[0], instance.incidentFormDetails

    return if not incident
    incident.userEventId = instance.data.userEventId
    incident.accepted = true
    instance.incidentCollection.update instance.incident._id,
      $unset:
        cases: true
        deaths: true
        specify: true
      $set: incident

    Modal.hide(instance)
