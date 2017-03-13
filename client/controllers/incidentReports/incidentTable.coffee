Template.incidentTable.onCreated ->
  @rowsSelected = new ReactiveVar(false)
  @selectedIncidents = new ReactiveVar([])

changeIncidentStatus = (status, instance) ->
  $.each instance.selectedIncidents.get(), (index, incidentId) ->
    incident = _id: incidentId
    incident.accepted = status
    Meteor.call 'updateIncidentReport', incident, false, (error, result) ->
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
    currentIds = instance.selectedIncidents.get()
    currentId = $(event.target).parent('tr').children('.count').data("incident-id")
    index = _.indexOf(currentIds, currentId)
    if index >= 0
      currentIds.splice(index, 1)
    else
      currentIds.push(currentId)
    $(event.target).parent('tr').toggleClass('active')
    instance.rowsSelected.set(currentIds.length > 0)

  'click .reject': (event, instance) ->
    changeIncidentStatus(false, instance)
