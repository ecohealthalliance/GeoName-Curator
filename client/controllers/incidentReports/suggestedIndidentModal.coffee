utils = require '/imports/utils.coffee'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'

Template.suggestedIncidentModal.onCreated ->
  @incidentCollection = @data.incidentCollection
  @incident = @data.incident or {}
  @incident.suggestedFields = new ReactiveVar(@incident.suggestedFields or [])

Template.suggestedIncidentModal.helpers
  hasSuggestedFields: ->
    Template.instance().incident.suggestedFields.get()

  type: -> [ 'case', 'date', 'location' ]

Template.suggestedIncidentModal.events
  'click .reject': (event, instance) ->
    Template.instance().incidentCollection.update instance.incident._id,
      $set:
        accepted: false

  'click .save-modal': (event, instance) ->
    incident = utils.incidentReportFormToIncident(instance.$("form")[0])

    return if not incident
    incident.suggestedFields = instance.incident.suggestedFields.get()
    incident.userEventId = instance.data.userEventId
    incident.accepted = true
    instance.incidentCollection.update instance.incident._id,
      $unset:
        cases: true
        deaths: true
        specify: true
      $set: incident

    Modal.hide(instance)
