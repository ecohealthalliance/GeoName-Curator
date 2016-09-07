Template.incidentReport.helpers
  formatDate: ->
    dateFormat = "MMM D, YYYY"
    if @dateRangeType is "day"
      if @cumulative
        return "Before " + moment(@endDate).format(dateFormat)
      else
        return moment(@startDate).format(dateFormat)
    else if @dateRangeType is "precise"
      return moment(@startDate).format(dateFormat) + " - " + moment(@endDate).format(dateFormat)
    return ""

Template.addIncidentReport.events
  "click .open-incident-form": (event, template) ->
    Modal.show("incidentModal", {articles: template.data.articles, userEventId: template.data.userEvent._id, add: true})
