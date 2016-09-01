Template.incidentReport.helpers
  travelIcon: ->
    if @travelRelated
      return "fa-check"
    return "fa-times"
  formatDate: (date) ->
    return moment(date).format("MMM D, YYYY")

Template.addIncidentReport.events
  "click .open-incident-form": (event, template) ->
    Modal.show("incidentModal", {articles: template.data.articles, userEventId: template.data.userEvent._id})