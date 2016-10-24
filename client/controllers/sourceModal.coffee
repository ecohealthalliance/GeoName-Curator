convertDate = require "/imports/convertDate.coffee"
utils = require '/imports/utils.coffee'
Articles = require '/imports/collections/articles.coffee'

Template.sourceModal.onCreated ->
  @tzIsSpecified = false
  @proMEDRegEx = /promedmail\.org\/post\/(\d+)/ig
  if @data.publishDate
    @timezoneFixedPublishDate = convertDate(@data.publishDate, "local",
                                              utils.UTCOffsets[@data.publishDateTZ])
  @suggestedArticles = new Mongo.Collection(null)
  Meteor.call 'queryForSuggestedArticles', @data.userEventId, (error, result) =>
    if result
      for suggestedArticle in result
        @suggestedArticles.insert {
          url: "http://www.promedmail.org/post/#{suggestedArticle.promedId}"
          subject: suggestedArticle.subject.raw
        }

Template.sourceModal.helpers
  timezones: ->
    timezones = []
    defaultTimezone = if moment().isDST() then 'EDT' else 'EST'
    for tzKey, tzOffset of utils.UTCOffsets
      timezones.push({name: tzKey, offset: tzOffset})
      if @publishDateTZ
        if @publishDateTZ is tzKey
          timezones[timezones.length-1].selected = true
      else if tzKey is defaultTimezone
        timezones[timezones.length-1].selected = true
    timezones
  initDatePicker: ->
    templateInstance = Template.instance()
    pickerOptions = {
      format: 'M/D/YYYY'
      inline: true
      useCurrent: false
    }
    if templateInstance.timezoneFixedPublishDate
      pickerOptions.defaultDate = moment(
        year: templateInstance.timezoneFixedPublishDate.year()
        month: templateInstance.timezoneFixedPublishDate.month()
        date: templateInstance.timezoneFixedPublishDate.date()
      )
    Meteor.defer ->
      templateInstance.$(".datePicker").datetimepicker pickerOptions
  initTimePicker: ->
    templateInstance = Template.instance()
    fixed = templateInstance.timezoneFixedPublishDate
    pickerOptions = {
      format: 'h:mm A'
      useCurrent: false
    }
    if templateInstance.timezoneFixedPublishDate
      pickerOptions.defaultDate = templateInstance.timezoneFixedPublishDate
    Meteor.defer ->
      $picker = templateInstance.$(".timePicker").datetimepicker pickerOptions
  saveButtonClass: ->
    if @edit
      return "save-edit-modal"
    return "save-modal"
  suggestedArticles: ->
    templateInstance = Template.instance()
    articles = templateInstance.suggestedArticles.find()
    if articles.count()
      articles
    else
      false

Template.sourceModal.events
  "click .save-modal": (e, templateInstance) ->
    form = templateInstance.$("form")[0]
    article = form.article.value
    validURL = form.article.checkValidity()
    datePicker = templateInstance.$('#publishDate').data("DateTimePicker")
    timePicker = templateInstance.$('#publishTime').data("DateTimePicker")
    date = datePicker.date()
    time = timePicker.date()

    unless validURL
      toastr.error('Please enter an article.')
      form.article.focus()
      return
    if !date and form.publishTime.value.length
      toastr.error('Please select a date.')
      return
    unless form.publishDateTZ.checkValidity()
      toastr.error('Please select a time zone.')
      form.publishDateTZ.focus()
      return

    source = {
      userEventId: templateInstance.data.userEventId
      url: article
      publishDateTZ: form.publishDateTZ.value
    }

    if date
      selectedDate = moment(
        year: date.year()
        month: date.month()
        date: date.date()
      )
      if form.publishTime.value.length
        selectedDate.set({hour: time.get("hour"), minute: time.get("minute")})
        selectedDate = convertDate(selectedDate,
                                    utils.UTCOffsets[source.publishDateTZ], "local")
      source.publishDate = selectedDate.toDate()

    enhance = form.enhance.checked
    Meteor.call("addEventSource", source, (error, articleId) ->
      if error
        toastr.error error.reason
      else
        Modal.hide(templateInstance)
        form.article.value = ""
        datePicker.date(null)
        timePicker.date(null)

        templateInstance.tzIsSpecified = false

        if enhance
          Modal.show("suggestedIncidentsModal", {
            userEventId: templateInstance.data.userEventId
            article: Articles.findOne(articleId)
          })
    )

  "click .save-edit-modal": (e, templateInstance) ->
    form = templateInstance.$("form")[0]
    datePicker = templateInstance.$('#publishDate').data("DateTimePicker")
    timePicker = templateInstance.$('#publishTime').data("DateTimePicker")
    date = datePicker.date()
    time = timePicker.date()

    if !date and form.publishTime.value.length
      toastr.error('Please select a date.')
      return
    unless form.publishDateTZ.checkValidity()
      toastr.error('Please select a time zone.')
      form.publishDateTZ.focus()
      return

    source = @
    source.publishDateTZ = form.publishDateTZ.value

    if date
      selectedDate = moment(
        year: date.year()
        month: date.month()
        date: date.date()
      )
      if form.publishTime.value.length
        selectedDate.set({hour: time.get("hour"), minute: time.get("minute")})
        selectedDate = convertDate(selectedDate,
                                    utils.UTCOffsets[source.publishDateTZ], "local")
      source.publishDate = selectedDate.toDate()

    Meteor.call("updateEventSource", source, (error, result) ->
      if error
        toastr.error error.reason
      else
        Modal.hide(templateInstance)
    )

  "change #publishDateTZ": (e, templateInstance) ->
    templateInstance.tzIsSpecified = true
  "input #article": (event, templateInstance) ->
    value = event.currentTarget.value.trim()
    match = templateInstance.proMEDRegEx.exec(value)
    if match
      articleId = Number(match[1])
      Meteor.call 'retrieveProMedArticleDate', articleId, (error, result) ->
        if result
          date = moment.utc(result)
          tz = if date.isDST() then 'EDT' else 'EST'
          date = date.utcOffset(utils.UTCOffsets[tz])
          templateInstance.$("#publishDateTZ option[value='#{tz}']")
            .prop('selected', true)
          templateInstance.$('#publishDate').data("DateTimePicker").date(date)
          templateInstance.$('#publishTime').data("DateTimePicker").date(date)

  "click #suggested-articles a": (event, templateInstance) ->
    event.preventDefault()
    url = event.currentTarget.getAttribute 'href'
    input = templateInstance.find('#article')
    input.value = url
    $(input).trigger('input').trigger('input')
