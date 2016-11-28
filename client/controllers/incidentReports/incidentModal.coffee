utils = require '/imports/utils.coffee'

Template.incidentModal.onCreated ->
  @incidentFormDetails =
    incidentStatus: new ReactiveVar(null)
    incidentType: new ReactiveVar(null)
    cumulative: new ReactiveVar(false)
    travelRelated: new ReactiveVar(false)

Template.incidentModal.helpers
  incidentFormDetails: ->
    Template.instance().incidentFormDetails

Template.incidentModal.events
  'click .save-modal, click .save-modal-duplicate': (event, instance) ->
    duplicate = $(event.target).hasClass('save-modal-duplicate')
    form = instance.$('form')[0]
    incident = utils.incidentReportFormToIncident form, instance.incidentFormDetails
    instanceData = instance.data

    if not incident
      return
    incident.userEventId = instanceData.userEventId

    if @add
      Meteor.call 'addIncidentReport', incident, (error, result) ->
        if not error
          $('.reactive-table tr').removeClass('open')
          $('.reactive-table tr.tr-details').remove()
          if !duplicate
            form.reset()
            Modal.hide('incidentModal')
          toastr.success('Incident report added to event.')
        else
          errorString = error.reason
          if error.details[0].name is 'locations' and error.details[0].type is 'minCount'
            errorString = 'You must specify at least one loction'
          toastr.error(errorString)

    if @edit
      incident._id = @incident._id
      incident.addedByUserId = @incident.addedByUserId
      incident.addedByUserName = @incident.addedByUserName
      incident.addedDate = @incident.addedDate
      Meteor.call 'editIncidentReport', incident, (error, result) ->
        if not error
          $('.reactive-table tr').removeClass('open')
          $('.reactive-table tr.details').remove()
          toastr.success('Incident report updated.')
          Modal.hide('incidentModal')
        else
          toastr.error(error.reason)
