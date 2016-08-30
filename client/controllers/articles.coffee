Template.articles.helpers
  getSettings: ->
    fields = [
      {
        key: "url"
        label: "Title"
        fn: (value, object, key) ->
          return value
      },
      {
        key: "addedDate"
        label: "Added"
        fn: (value, object, key) ->
          return moment(value).fromNow()
      }
      {
        key: "publishDate"
        label: "Reported"
        fn: (value, object, key) ->
          return moment(value).fromNow()
      }
    ]

    fields.push({
      key: "expand"
      label: ""
      cellClass: "open-row-right"
    })

    return {
      id: 'event-sources-table'
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showRowCount: false
      class: "table"
    }

Template.articles.onCreated ->
  @tzIsSpecified = false

Template.articles.onRendered ->
  @proMEDRegEx = /promedmail\.org\/post\/(\d+)/ig

Template.sourceModal.helpers
  timezones: ->
    timezones = []
    defaultTimezone = if moment().isDST() then 'EDT' else 'EST'
    for tzKey, tzOffset of UTCOffsets
      timezones.push({name: tzKey, offset: tzOffset})
      if tzKey is defaultTimezone
        timezones[timezones.length-1].selected = true
    timezones
  initDatePicker: ->
    templateInstance = Template.instance()
    Meteor.defer ->
      templateInstance.$(".datePicker").datetimepicker
        format: 'M/D/YYYY hh:mm A'
        useCurrent: false

Template.articles.events
  "click .open-source-form": (event, template) ->
    Modal.show("sourceModal", {userEventId: template.data.userEvent._id})
Template.sourceModal.events
  "change #publishDateTZ": (e, templateInstance) ->
    templateInstance.tzIsSpecified = true
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

          templateInstance.tzIsSpecified = false

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
          date = moment(result)
          if !templateInstance.tzIsSpecified
            tz = if date.isDST() then 'EDT' else 'EST'
            templateInstance.$("#publishDateTZ option[value='#{tz}']")
              .prop('selected', true)
          dateString = date.format("M/D/YYYY hh:mm A")
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
      $input.next(".select2-container").css("width", "100%")

Template.articleSelect2.onDestroyed ->
  templateInstance = Template.instance()
  templateInstance.$("#" + templateInstance.data.selectId).select2("destroy")
