Template.sourceModal.onCreated ->
  @tzIsSpecified = false
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
        format: 'M/D/YYYY'
        inline: true
        useCurrent: false
  initTimePicker: ->
    templateInstance = Template.instance()
    Meteor.defer ->
      templateInstance.$(".timePicker").datetimepicker
        format: 'hh:mm A'
        useCurrent: false

Template.sourceModal.events
  "click .save-modal": (e, templateInstance) ->
    form = templateInstance.$("form")[0]
    article = form.article.value
    validURL = form.article.checkValidity()
    datePicker = templateInstance.$('#publishDate').data("DateTimePicker")
    timePicker = templateInstance.$('#publishTime').data("DateTimePicker")
    date = datePicker.date()
    time = timePicker.date()
    dateString = ""

    unless validURL
      toastr.error('Please enter an article.')
      form.article.focus()
      return
    if !date and time
      toastr.error('Please select a date.')
      return
    unless form.publishDateTZ.checkValidity()
      toastr.error('Please select a time zone.')
      form.publishDateTZ.focus()
      return

    if date
      dateString = date.format("M/D/YYYY")
      if time
        dateString += time.format(" hh:mm A")

    source = {
      userEventId: templateInstance.data.userEventId
      url: article
      publishDate: dateString
      publishDateTZ: form.publishDateTZ.value
    }

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
            article:
              _id: articleId
              url: article
          })
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
          date = moment(result)
          if !templateInstance.tzIsSpecified
            tz = if date.isDST() then 'EDT' else 'EST'
            templateInstance.$("#publishDateTZ option[value='#{tz}']")
              .prop('selected', true)
          templateInstance.$('#publishDate').data("DateTimePicker").date(date)
          templateInstance.$('#publishTime').data("DateTimePicker").date(date)
