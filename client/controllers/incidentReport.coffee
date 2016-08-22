Template.incidentReport.events
  "click .delete-count": (e) ->
    if window.confirm("Are you sure you want to delete this incident report?")
      Meteor.call("removeEventCount", @_id)
