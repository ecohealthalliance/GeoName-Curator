Template.count.events
  "click .delete-count": (e) ->
    if window.confirm("Are you sure you want to delete this count?")
      Meteor.call("removeEventCount", @_id)
