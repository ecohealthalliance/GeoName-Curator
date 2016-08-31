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
        format: 'M/D/YYYY hh:mm A'
        useCurrent: false

Template.sourceModal.events
  "click .save-modal, click .save-modal-close": (e, templateInstance) ->
    closeModal = $(e.target).hasClass("save-modal-close")
    form = templateInstance.$("form")[0]
    article = form.article.value
    validURL = form.article.checkValidity()
    unless validURL
      toastr.error('Please enter an article.')
      form.article.focus()
      return
    unless form.publishDate.checkValidity()
      toastr.error('Please provide a valid date.')
      form.publishDate.focus()
      return
    unless form.publishDateTZ.checkValidity()
      toastr.error('Please select a time zone.')
      form.publishDateTZ.focus()
      return

    source = {
      userEventId: templateInstance.data.userEventId
      url: article
      publishDate: form.publishDate.value
      publishDateTZ: form.publishDateTZ.value
    }

    enhance = form.enhance.checked
    Meteor.call("addEventSource", source, (error, articleId) ->
      if error
        toastr.error error.reason
      else
        form.article.value = ""
        form.publishDate.value = ""

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
          dateString = date.format("M/D/YYYY hh:mm A")
          templateInstance.$('#publishDate').val(dateString).trigger('change')
