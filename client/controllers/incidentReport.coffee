Template.incidentReport.helpers
  formatDate: ->
    if @specificDate
      startMoment = moment(@startDate)
      endMoment = moment(@endDate)
      diff = endMoment.diff(startMoment, "hours")
      if diff is 1
        return moment(@startDate).format("MMM D, YYYY h:mm A")
      else
        return moment(@startDate).format("MMM D, YYYY")
    else
      return " - "

Template.addIncidentReport.events
  "click .open-incident-form": (event, template) ->
    Modal.show("incidentModal", {articles: template.data.articles, userEventId: template.data.userEvent._id, add: true})
