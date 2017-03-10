Template.incidentTable.onCreated ->
  @rowsSelected = new ReactiveVar(false)

selectedIncidents = (event, instance) ->
  # return all the selected incident-ids
  $('table.incident-table tr.active td.count').map(() ->
    $(this).data("incident-id")
  ).get()

changeIncidentStatus = (status) ->
  incidentIds = selectedIncidents()
  $.each incidentIds, (index, incidentId) ->
    Meteor.call 'getIncidentReport', incidentId, (error, incident) ->
      incident.accepted = status
      Meteor.call 'editIncidentReport', incident, false, (error, result) ->
        if error
          console.log "ERROR calling editIncidentReport", error
          toastr.error("There was a problem updating your incident reports!")
          return
        toastr.success("Incidents reports udpated!")

Template.incidentTable.helpers
  showMultiActions: ->
    Template.instance().rowsSelected.get()

Template.incidentTable.events
  'click table.incident-table tr': (event, instance) ->
    $(event.target).parent('tr').toggleClass('active')
    instance.rowsSelected.set($('table.incident-table tr.active').length > 0)

  'click .reject': (event, instance) ->
    changeIncidentStatus(false)

  'click .confirm': (event, instance) ->
    changeIncidentStatus(true)
