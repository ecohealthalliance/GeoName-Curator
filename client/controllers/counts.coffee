formatLocation = (name, sub, country) ->
  text = name
  if sub
    text += ", " + sub
  if country
    text += ", " + country
  return text

Template.counts.onRendered ->
  $(document).ready(() ->
    $(".datePicker").datetimepicker({
      format: "M/D/YYYY",
      useCurrent: false
    })
    $("#count-location-select2").select2({
      placeholder: "Search for a location..."
      minimumInputLength: 1
      ajax: {
        url: "http://api.geonames.org/searchJSON"
        data: (params) ->
          return {
            username: "eha_eidr"
            q: params.term
            style: "full"
            maxRows: 10
          }
        delay: 600
        processResults: (data, params) ->
          results = []
          for loc in data.geonames
            results.push({id: loc.geonameId, text: formatLocation(loc.toponymName, loc.adminName1, loc.countryName), item: loc})
          return {results: results}
      }
    })
    $(".select2-container").css("width", "100%")
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
