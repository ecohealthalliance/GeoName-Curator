Template.counts.onRendered ->
  $(document).ready(() ->
    $(".datePicker").datetimepicker({
      format: "M/D/YYYY",
      useCurrent: false
    })

    $("#countArticles").select2({
      tags: true
    })
  )

Template.counts.events
  "submit #add-count": (e, templateInstance) ->
    event.preventDefault()
    $articleSelect = templateInstance.$(e.target.countArticles)
    validURL = e.target.countArticles.checkValidity()
    unless validURL
      toastr.error('Please select an article.')
      e.target.countArticles.focus()
      return
    unless e.target.date.checkValidity()
      toastr.error('Please provide a valid date.')
      e.target.publishDate.focus()
      return
    unless e.target.cases.checkValidity() || e.target.deaths.checkValidity()
      toastr.error('Please provide a valid case or death count.')
      e.target.cases.focus()
      return

    article = ""
    for child in $articleSelect.select2("data")
      if child.selected
        article = child.text.trim()

    $loc = templateInstance.$("#count-location-select2")
    allLocations = []

    for option in $loc.select2("data")
      allLocations.push(
        geonameId: option.item.id
        name: option.item.name
        displayName: option.item.name
        countryName: option.item.countryName
        subdivision: option.item.admin1Name
        latitude: option.item.latitude
        longitude: option.item.longitude
      )

    if article.length isnt 0
      Meteor.call("addEventCount", templateInstance.data.userEvent._id, article, allLocations, e.target.cases.value, e.target.deaths.value, e.target.date.value, (error, result) ->
        if not error
          countId = result
          $articleSelect.select2('val', '')
          e.target.date.value = ""
          e.target.cases.value = ""
          e.target.deaths.value = ""
          templateInstance.$("#count-location-select2").select2('val', '')
          toastr.success("Count added to event.")
        else
          toastr.error(error.reason)
      )
