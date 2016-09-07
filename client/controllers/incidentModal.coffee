utils = require '/imports/utils.coffee'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'

Template.incidentModal.events
  "click .save-modal, click .save-modal-close": (e, templateInstance) ->
    closeModal = $(e.target).hasClass("save-modal-close")
    incident = utils.incidentReportFormToIncident(templateInstance.$("form")[0])
    if not incident
      return
    incident.userEventId = templateInstance.data.userEventId
    Meteor.call("addIncidentReport", incident, (error, result) ->
      if not error
        $(".reactive-table tr").removeClass("details-open")
        $(".reactive-table tr.tr-details").remove()
        if closeModal
          Modal.hide(templateInstance)
        toastr.success("Incident report added to event.")
      else
        toastr.error(error.reason)
    )
