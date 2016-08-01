Template.article.events
  "click .delete-article": (e) ->
    if window.confirm("Delete article?")
      grid.Articles.remove(@_id)
