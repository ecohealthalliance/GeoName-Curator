Template.comments.helpers
  checkComments: ->
    @comments.count() > 0

Template.comments.events
  "submit #add-comment": (e) ->
    e.preventDefault()
    comment = e.target.comment.value
    if comment
      grid.Comments.insert
        comment: e.target.comment.value
        event: @event.eidID
        userID: Meteor.user()._id
        username: Meteor.user().profile?.name
      e.target.comment.value = ''
