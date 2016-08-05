Template.counts.onRendered ->
  $(document).ready(() ->
    $(".datePicker").datetimepicker({
      format: "M/D/YYYY",
      useCurrent: false
    })
  )

Template.counts.events
  "submit #add-count": (e, templateInstance) ->
    event.preventDefault()
    validURL = e.target.article.checkValidity()
    unless validURL
      toastr.error('Please provide a correct URL address')
      e.target.article.focus()
      return
    unless e.target.date.checkValidity()
      toastr.error('Please provide a valid date.')
      e.target.publishDate.focus()
      return
    article = e.target.article.value.trim()

    $loc = $("#count-location-select2")
    allLocations = []

    for option in $loc.select2("data")
      allLocations.push({
        geonameId: option.item.geonameId,
        name: option.item.name,
        displayName: option.item.toponymName,
        countryName: option.item.countryName,
        subdivision: option.item.adminName1,
        latitude: option.item.lat,
        longitude: option.item.lng,
      })

    if article.length isnt 0
      Meteor.call("addEventCount", templateInstance.data.userEvent._id, article, allLocations, e.target.cases.value, e.target.deaths.value, e.target.date.value, (error, result) ->
        if not error
          countId = result
          e.target.article.value = ""
          e.target.date.value = ""
          e.target.cases.value = ""
          e.target.deaths.value = ""
          $("#count-location-select2").select2('val', '')
          toastr.success("Count added to event.")
      )

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
