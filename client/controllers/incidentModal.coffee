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
    if this.add
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
          toastr.success("Incident report added to event.")
        else
          errorString = error.reason
          if error.details[0].name is "locations" and error.details[0].type is "minCount"
            errorString = "You must specify at least one loction"
          toastr.error(errorString)
      )
    if this.edit
      incident._id = this.incident._id
      incident.addedByUserId = this.incident.addedByUserId
      incident.addedByUserName = this.incident.addedByUserName
      incident.addedDate = this.incident.addedDate
      Meteor.call("editIncidentReport", incident, (error, result) ->
        if not error
          $(".reactive-table tr").removeClass("details-open")
          $(".reactive-table tr.tr-details").remove()
          toastr.success("Incident report updated.")
        else
          toastr.error(error.reason)
    )
