Template.articles.onRendered ->
  $(document).ready(() ->
    $(".datePicker").datetimepicker({
      format: "M/D/YYYY",
      useCurrent: false
    })
  )

Template.articles.events
  "submit #add-article": (e, templateInstance) ->
    event.preventDefault()
    validURL = e.target.article.checkValidity()
    unless validURL
      toastr.error('Please provide a correct URL address')
      e.target.article.focus()
      return
    unless e.target.publishDate.checkValidity()
      toastr.error('Please provide a valid date.')
      e.target.publishDate.focus()
      return
    article = e.target.article.value.trim()
    scrapeLocations = e.target.scrapeLocations.checked
    
    if article.length isnt 0
      Meteor.call("addEventArticle", @userEvent._id, article, e.target.publishDate.value, (error, result) ->
        if not error
          e.target.article.value = ""
          e.target.publishDate.value = ""
          e.target.scrapeLocations.checked = false
          
          if scrapeLocations
            articleLocations = []
            existingLocations = []
            
            for loc in @locations
              existingLocations.push(loc.geonameId.toString())
            
            Modal.show("loadingModal")
            
            Meteor.call("getArticleLocations", article, (error, result) ->
              if result and result.length
                for loc in result
                  if existingLocations.indexOf(loc.geonameId) is -1
                    articleLocations.push(loc)
              
              Modal.hide()
              Modal.show("locationModal", {userEventId:templateInstance.data.userEvent._id, suggestedLocations: articleLocations})
            )
      )