Template.incidentTable.onCreated ->

changeIncidentStatus = (status, instance) ->
  $.each instance.data.incidents.find({selected: true}).fetch(), (index, incident) ->  
    incident = _id: incident._id
    incident.accepted = status
    Meteor.call 'updateIncidentReport', incident, false, (error, result) ->
      if error
        console.log "ERROR calling editIncidentReport", error
        toastr.error("There was a problem updating your incident reports!")
        return
      toastr.success("Incidents reports udpated!")

Template.incidentTable.helpers
  incidents: ->
    Template.instance().data.incidents.find()

  showMultiActions: ->
    Template.instance().data.incidents.find({selected: true}).fetch().length > 0

Template.incidentTable.events
  'click table.incident-table tr': (event, instance) ->
    currentId = $(event.target).parent('tr').children('.count').data("incident-id")
    instance.data.incidents.update({_id: currentId}, {$set: {selected: true}})
    $(event.target).parent('tr').toggleClass('active')

  'click .reject': (event, instance) ->
    changeIncidentStatus(false, instance)
