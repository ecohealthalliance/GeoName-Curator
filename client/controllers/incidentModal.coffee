utils = require '/imports/utils.coffee'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'

Template.incidentModal.events
  "click .save-modal, click .save-modal-duplicate": (e, templateInstance) ->
    duplicate = $(e.target).hasClass("save-modal-duplicate")
    form = templateInstance.$("form")[0]
    incident = utils.incidentReportFormToIncident(form)
    if not incident
      return
    incident.userEventId = templateInstance.data.userEventId
    Meteor.call("addIncidentReport", incident, (error, result) ->
      if not error
        $(".reactive-table tr").removeClass("details-open")
        $(".reactive-table tr.tr-details").remove()
        if !duplicate
           $("#articleSource").val(null).trigger("change")
           $(form.date).val("")
           $("#incident-location-select2").val(null).trigger("change")
           $(form.species).val("")
           $(form.status).val(null)
           $(form.count).val("")
           $(form.incidentType).val(null).trigger("change")
           $(form.travelRelated).attr('checked', false)
        if closeModal
          Modal.hide(templateInstance)
        toastr.success("Incident report added to event.")
      else
        toastr.error(error.reason)
    )
