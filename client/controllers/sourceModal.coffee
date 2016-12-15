convertDate = require "/imports/convertDate.coffee"
Articles = require '/imports/collections/articles.coffee'
createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'

import {UTCOffsets, cleanUrl} from '/imports/utils.coffee'

_setDatePicker = (picker, date) ->
  picker.setStartDate(date)
  picker.clickApply()

Template.sourceModal.onCreated ->
  @tzIsSpecified = false
  @proMEDRegEx = /promedmail\.org\/post\/(\d+)/ig
  @selectedArticle = new ReactiveVar()
  @selectedArticle.set @data
  @loadingArticles = new ReactiveVar(true)
  if @data.publishDate
    @timezoneFixedPublishDate = convertDate(@data.publishDate, "local",
                                              UTCOffsets[@data.publishDateTZ])
  @suggestedArticles = new Mongo.Collection(null)
  Meteor.call 'queryForSuggestedArticles', @data.userEventId, (error, result) =>
    @loadingArticles.set(false)
    if result
      for suggestedArticle in result
        @suggestedArticles.insert
          url: "http://www.promedmail.org/post/#{suggestedArticle.promedId}"
          subject: suggestedArticle.subject.raw

Template.sourceModal.onRendered ->
  pickerOptions =
    format: 'M/D/YYYY'
    inline: true
    useCurrent: false
    singleDatePicker: true
    startDate: @timezoneFixedPublishDate or new Date()
  @datePicker = createInlineDateRangePicker(@$('#publishDate'), pickerOptions)

  pickerOptions =
    format: 'h:mm A'
    useCurrent: false
    defaultDate:  @timezoneFixedPublishDate or false
  @$('.timePicker').datetimepicker(pickerOptions)

Template.sourceModal.helpers
  timezones: ->
    timezones = []
    defaultTimezone = if moment().isDST() then 'EDT' else 'EST'
    for tzKey, tzOffset of UTCOffsets
      timezones.push({name: tzKey, offset: tzOffset})
      if @publishDateTZ
        if @publishDateTZ is tzKey
          timezones[timezones.length-1].selected = true
      else if tzKey is defaultTimezone
        timezones[timezones.length-1].selected = true
    timezones

  saveButtonClass: ->
    if @edit
      return "save-edit-modal"
    return "save-modal"

  title: ->
    Template.instance().selectedArticle.get().title

  suggestedArticles: ->
    Template.instance().suggestedArticles.find()

  loadingArticles: ->
    Template.instance().loadingArticles.get()

  articleSelected: ->
    @_id is Template.instance().selectedArticle.get()._id

Template.sourceModal.events
  "click .save-modal": (e, instance) ->
    form = instance.$("form")[0]
    article = form.article.value
    validURL = form.article.checkValidity()
    timePicker = instance.$('#publishTime').data('DateTimePicker')
    date = instance.datePicker.startDate
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

    source =
      userEventId: instance.data.userEventId
      url: cleanUrl(article)
      publishDateTZ: form.publishDateTZ.value
      title: form.title.value

    if date
      selectedDate = moment
        year: date.year()
        month: date.month()
        date: date.date()
      if form.publishTime.value.length
        selectedDate.set({hour: time.get('hour'), minute: time.get('minute')})
        selectedDate = convertDate(selectedDate,
                                    UTCOffsets[source.publishDateTZ], 'local')
      source.publishDate = selectedDate.toDate()

    enhance = form.enhance.checked
    Meteor.call 'addEventSource', source, (error, articleId) ->
      if error
        toastr.error error.reason
      else
        Modal.hide(instance)
        form.article.value = ""
        _setDatePicker(instance.datePicker, null)
        timePicker.date(null)

        instance.tzIsSpecified = false

        if enhance
          Modal.show 'suggestedIncidentsModal',
            userEventId: instance.data.userEventId
            article: Articles.findOne(articleId)

  'click .save-edit-modal': (e, instance) ->
    form = instance.$("form")[0]
    timePicker = instance.$('#publishTime').data('DateTimePicker')
    date = instance.datePicker.startDate
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
      selectedDate = moment
        year: date.year()
        month: date.month()
        date: date.date()
      if form.publishTime.value.length
        selectedDate.set({hour: time.get('hour'), minute: time.get('minute')})
        selectedDate = convertDate(selectedDate,
                                    UTCOffsets[source.publishDateTZ], 'local')
      source.publishDate = selectedDate.toDate()

    Meteor.call 'updateEventSource', source, (error, result) ->
      if error
        toastr.error error.reason
      else
        Modal.hide(instance)

  'change #publishDateTZ': (e, instance) ->
    instance.tzIsSpecified = true

  'input #article': (event, instance) ->
    value = event.currentTarget.value.trim()
    match = instance.proMEDRegEx.exec(value)
    if match
      articleId = Number(match[1])
      Meteor.call 'retrieveProMedArticleDate', articleId, (error, result) ->
        if result
          date = moment.utc(result)
          # Aproximate DST for New York timezone
          daylightSavings = moment.utc("#{date.year()}-03-08") <= date
          daylightSavings = daylightSavings and moment.utc(
            date.year() + "-11-01") >= date
          tz = if daylightSavings then 'EDT' else 'EST'
          date = date.utcOffset(UTCOffsets[tz])
          instance.$('#publishDateTZ').val(tz)
          _setDatePicker(instance.datePicker, date)
          instance.$('#publishTime').data('DateTimePicker').date(date)

  'click #suggested-articles li': (event, instance) ->
    event.preventDefault()
    instance.selectedArticle.set(@)
    input = instance.find('#article')
    input.value = @url
    titleInput = instance.find('#title')
    titleInput.value = @subject
    $(input).trigger('input').trigger('input')
