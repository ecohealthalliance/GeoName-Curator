Template.articles.onRendered ->
  @ProMEDRegEx = /promedmail\.org\/post\/(\d+)/ig
  $(document).ready =>
    @$(".datePicker").datetimepicker
      format: "M/D/YYYY",
      useCurrent: false

Template.articles.events
  "submit #add-article": (e, templateInstance) ->
    event.preventDefault()
    validURL = e.target.article.checkValidity()
    unless validURL
      toastr.error('Please provide a correct URL address')
      e.target.article.focus()
      return
    unless e.target.publishDate.checkValidity()
      toastr.error('Please provide a valid date')
      e.target.publishDate.focus()
      return
    article = e.target.article.value.trim()
    scrapeLocations = e.target.scrapeLocations.checked

    if article.length isnt 0
      Meteor.call("addEventArticle", templateInstance.data.userEvent._id, article, e.target.publishDate.value, (error, result) ->
        if not error
          articleId = result
          e.target.article.value = ""
          e.target.publishDate.value = ""
          e.target.scrapeLocations.checked = false

          if scrapeLocations
            articleLocations = []
            existingLocations = []

            for loc in templateInstance.data.locations
              existingLocations.push(loc.geonameId.toString())

            Modal.show("loadingModal")

            Meteor.call("getArticleLocations", article, (error, result) ->
              if result and result.length
                for loc in result
                  if existingLocations.indexOf(loc.geonameId) is -1
                    articleLocations.push(loc)

              Modal.hide()
              Modal.show("locationModal", {
                userEventId:templateInstance.data.userEvent._id,
                suggestedLocations: articleLocations,
                article: {articleId: articleId, url: article}
              })
            )
      )
  "input #article": _.throttle((event, templateInstance) ->
    value = event.currentTarget.value.trim()
    match = templateInstance.ProMEDRegEx.exec(value)
    if match
      articleId = match[1]
      Meteor.call 'retrieveProMedArticleDate', articleId, (error, result) ->
        if result
          date = new Date(result)
          dateString = date.getMonth()+1 + '/' + date.getDate() + '/' +
                        date.getFullYear()
          templateInstance.$('#publishDate').val(dateString).trigger('change')
  , 1000)


Template.articleSelect2.onRendered ->
  templateData = Template.instance().data

  $(document).ready(() ->
    $input = $("#" + templateData.selectId)

    $input.select2({
      multiple: true
    })

    if templateData.selected
      $input.val(templateData.selected).trigger("change")
    $(".select2-container").css("width", "100%")
  )

Template.articleSelect2.onDestroyed ->
  $("#" + Template.instance().data.selectId).select2("destroy")
