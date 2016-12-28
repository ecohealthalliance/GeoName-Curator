convertDate = require '/imports/convertDate.coffee'
Articles = require '/imports/collections/articles.coffee'
createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'
validator = require 'bootstrap-validator'


import {UTCOffsets, cleanUrl} from '/imports/utils.coffee'

_checkFormValidity = (instance) ->
  $form = instance.$('form')
  $form.validator('validate')
  $form.submit()
  instance.formValid.get()

_setDatePicker = (picker, date) ->
  picker.setStartDate(date)
  picker.clickApply()

Template.sourceModal.onCreated ->
  @tzIsSpecified = false
  @proMEDRegEx = /promedmail\.org\/post\/(\d+)/ig
  @selectedArticle = new ReactiveVar(@data)

  if @data.edit
    if @data.publishDate
      @timezoneFixedPublishDate = convertDate(@data.publishDate, 'local',
                                                UTCOffsets[@data.publishDateTZ])
  else
    @loadingArticles = new ReactiveVar(true)
    @suggestedArticles = new Mongo.Collection(null)
    Meteor.call 'queryForSuggestedArticles', @data.userEventId, (error, result) =>
      @loadingArticles.set(false)
      if result
        for suggestedArticle in result
          @suggestedArticles.insert
            url: "http://www.promedmail.org/post/#{suggestedArticle.promedId}"
            subject: suggestedArticle.subject.raw

Template.sourceModal.onCreated ->
  @formValid = new ReactiveVar false

Template.sourceModal.onRendered ->
  publishDate = @timezoneFixedPublishDate
  pickerOptions =
    singleDatePicker: true
  if publishDate
    pickerOptions.startDate = publishDate
  @datePicker = createInlineDateRangePicker(@$('#publishDate'), pickerOptions)

  pickerOptions =
    format: 'h:mm A'
    useCurrent: false
    defaultDate:  publishDate or false
  @$('.timePicker').datetimepicker(pickerOptions)

  @$('#add-source').validator()

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
      'save-edit-modal'
    else
      'save-modal'

  title: ->
    Template.instance().selectedArticle.get().title

  suggestedArticles: ->
    Template.instance().suggestedArticles.find()

  loadingArticles: ->
    Template.instance().loadingArticles.get()

  articleSelected: ->
    @_id is Template.instance().selectedArticle.get()._id

  editing: ->
    Template.instance().data.edit

Template.sourceModal.events
  'click .save-modal': (event, instance) ->
    return unless _checkFormValidity(instance)
    form = instance.$('form')[0]
    article = form.article.value
    validURL = form.article.checkValidity()
    timePicker = instance.$('#publishTime').data('DateTimePicker')
    date = instance.datePicker.startDate
    time = timePicker.date()

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
        form.article.value = ''
        _setDatePicker(instance.datePicker, null)
        timePicker.date(null)

        instance.tzIsSpecified = false

        if enhance
          Modal.show 'suggestedIncidentsModal',
            userEventId: instance.data.userEventId
            article: Articles.findOne(articleId)

  'click .save-edit-modal': (event, instance) ->
    return unless _checkFormValidity(instance)
    form = instance.$('form')[0]
    timePicker = instance.$('#publishTime').data('DateTimePicker')
    date = instance.datePicker.startDate
    time = timePicker.date()

    source = @
    source.publishDateTZ = form.publishDateTZ.value
    source.title = form.title.value

    if date
      selectedDate = moment
        year: date.year()
        month: date.month()
        date: date.date()
      if form.publishTime.value.length
        selectedDate.set
          hour: time.get('hour')
          minute: time.get('minute')
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
    articleInput = instance.find('#article')
    articleInput.value = @url
    $(articleInput).trigger('input')
    titleInput = instance.find('#title')
    titleInput.value = @subject

  'submit form': (event, instance) ->
    instance.formValid.set(not event.isDefaultPrevented())
    event.preventDefault()

  'change input[name=daterangepicker_start]': (event, instance) ->
    instance.datePicker.clickApply()
