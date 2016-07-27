Meteor.publish "comments", (eventID) ->
  grid.Comments.find({"event": eventID})
