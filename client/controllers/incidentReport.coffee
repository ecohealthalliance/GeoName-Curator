Template.incidentReport.helpers
  travelIcon: ->
    if @travelRelated
      return "fa-check"
    return "fa-times"
  formatDate: (date) ->
    return moment(date).format("MMM D, YYYY")

Template.incidentReport.events
  "click .delete-count": (e) ->
    if window.confirm("Are you sure you want to delete this incident report?")
      Meteor.call("removeEventCount", @_id)
