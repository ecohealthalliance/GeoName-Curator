Template.article.events
  "click .delete-article": (e) ->
    if window.confirm("Delete article?")
      id = e.target.getAttribute('article-id')
      grid.Articles.remove(id)
