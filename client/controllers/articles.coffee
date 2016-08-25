Template.articles.onRendered ->
  @proMEDRegEx = /promedmail\.org\/post\/(\d+)/ig
  @isAMorPM = (hours) ->
    if (hours != 0 && hours > 12) then 'PM' else 'AM'

Template.articles.helpers
  timezones: ->
    a = []
    for k,v of UTCOffsets
      a.push({name: k, offset: v})
      if k is 'EST'
        a[a.length-1].selected = true
    a
  initDatePicker: ->
    templateInstance = Template.instance()
    Meteor.defer ->
      templateInstance.$(".datePicker").datetimepicker
        format: 'M/D/YYYY hh:mm A'
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
      Meteor.call("addEventArticle", templateInstance.data.userEvent._id, article, e.target.publishDate.value, e.target.publishDateTZ.value, (error, result) ->
        if error
          toastr.error error.reason
        else
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
  "input #article": (event, templateInstance) ->
    value = event.currentTarget.value.trim()
    match = templateInstance.proMEDRegEx.exec(value)
    if match
      articleId = Number(match[1])
      Meteor.call 'retrieveProMedArticleDate', articleId, (error, result) ->
        if result
          date = new Date(result)
          dateString = date.getMonth()+1 + '/' + date.getDate() + '/' +
                        date.getFullYear() +
                        ' ' + (date.getHours()-1) + ':' + date.getMinutes() +
                        ' ' + templateInstance.isAMorPM(date.getHours())
          templateInstance.$('#publishDate').val(dateString).trigger('change')

Template.articleSelect2.helpers
  initArticleSelect2: ->
    templateInstance = Template.instance()
    templateData = templateInstance.data

    Meteor.defer ->
      $input = templateInstance.$("#" + templateData.selectId)
      options = {}

      if templateData.multiple
        options.multiple = true

      $input.select2(options)

      if templateData.selected
        $input.val(templateData.selected).trigger("change")
      templateInstance.$(".select2-container").css("width", "100%")

Template.articleSelect2.onDestroyed ->
  templateInstance = Template.instance()
  templateInstance.$("#" + templateInstance.data.selectId).select2("destroy")
