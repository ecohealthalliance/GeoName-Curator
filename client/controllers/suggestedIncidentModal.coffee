utils = require '/imports/utils.coffee'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'

Template.suggestedIncidentModal.onCreated ->
  @incidentCollection = @data.incidentCollection
  @incident = @data.incident
Template.suggestedIncidentModal.events
  "click .reject": (event, templateInstance) ->
    Template.instance().incidentCollection.update(templateInstance.incident._id, {
      $set:
        accepted: false
    })
  "click .save-modal": (e, templateInstance) ->
    incident = utils.incidentReportFormToIncident(templateInstance.$("form")[0])
    if not incident
      return
    incident.userEventId = templateInstance.data.userEventId
    incident.accepted = true
    templateInstance.incidentCollection.update(templateInstance.incident._id, {
      $unset:
        cases: true
        deaths: true
        specify: true
      $set: incident
    })
    Modal.hide(templateInstance)
