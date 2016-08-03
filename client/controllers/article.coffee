Template.article.events
  "click .delete-article": (e) ->
    if window.confirm("Are you sure you want to delete this article?\nAll locations mentioned only in this article will be deleted as well.")
      Meteor.call("removeEventArticle", @_id)
