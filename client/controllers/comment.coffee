Template.comment.events
  'click .delete-comment': (event) ->
    if window.confirm("Delete comment?")
      commentId = event.target.getAttribute('comment-id')
      grid.Comments.remove(commentId)
