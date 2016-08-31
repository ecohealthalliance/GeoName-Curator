Template.article.events
  "click .delete-article": (e) ->
    incidentCount = Incidents.find({url: @url}).count()
    if incidentCount
      plural = if incidentCount is 1 then "" else "s"
      message = "There " + (if incidentCount is 1 then "is an incident report" else "are #{incidentCount} incident reports") + " associated with this article. Please delete the incident report#{plural} before deleting the article."
      toastr.error(message)
    else if window.confirm("Are you sure you want to delete this article?")
      Meteor.call("removeEventArticle", @_id)
