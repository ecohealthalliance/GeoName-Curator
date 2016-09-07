Template.incidentReport.helpers
  formatDate: ->
    timezoneString = ""
    if @timezone
      timezoneString = " " + @timezone + " " + @timezoneOffset
    dateFormat = "MMM D, YYYY"
    if @hourPrecision
      dateFormat = "MMM D, YYYY h:mm A"
    if @dateRangeType is "day"
      return moment(@startDate).format(dateFormat) + timezoneString
    else if @dateRangeType is "precise"
      return moment(@startDate).format(dateFormat) + " - " + moment(@endDate).format(dateFormat) + timezoneString
    else if @dateRangeType is "unbounded"
      if @startDate
        return "After " + moment(@startDate).format(dateFormat) + timezoneString
      else
        return "Before " + moment(@endDate).format(dateFormat) + timezoneString
    return ""

Template.addIncidentReport.events
  "click .open-incident-form": (event, template) ->
    Modal.show("incidentModal", {articles: template.data.articles, userEventId: template.data.userEvent._id, add: true})
