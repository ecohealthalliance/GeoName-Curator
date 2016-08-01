formatLocation = (name, sub, country) ->
  text = name
  if sub
    text += ", " + sub
  if country
    text += ", " + country
  return text

Template.locationList.onRendered ->
  $(document).ready(() ->
    $("#location-select2").select2({
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
    $("#article-select2").select2({
      placeholder: "Select at least one article"
      multiple: true
    })
    $(".select2-container").css("width", "100%")
  )

Template.location.helpers
  formatLocation: (location) ->
    return formatLocation(location.displayName, location.subdivision, location.countryName)

Template.locationList.events
  "click #add-location": (event, template) ->
    $loc = $("#location-select2")
    $art = $("#article-select2")
    allLocations = []
    allArticles = $art.val()

    for option in $loc.select2("data")
      allLocations.push({
        geonameId: option.item.geonameId,
        name: option.item.name,
        displayName: option.item.toponymName,
        countryName: option.item.countryName,
        subdivision: option.item.adminName1,
        latitude: option.item.lat,
        longitude: option.item.lng,
        articles: allArticles
      })

    unless allLocations.length
      toastr.error('Please select a location')
      $loc.focus()
      return

    unless allArticles.length
      toastr.error("Please select at least one article that references the location")
      $art.focus()
      return

    Meteor.call("addEventLocations", template.data.userEvent._id, allLocations, (error, result) ->
      if not error
        $new.select2("val", "")
    )

  "click .remove-location": (event, template) ->
    if confirm("Do you want to delete the selected location?")
      Meteor.call("removeEventLocation", @_id)

Template.locationModal.helpers
  locationOptionText: (location) ->
    return formatLocation(location.displayName, location.subdivision, location.countryCode)

Template.locationModal.events
  "click #add-suggestions": (event, template) ->
    geonameIds = []
    allLocations = []
    $("#suggested-locations-form").find("input:checked").each(() ->
      geonameIds.push($(this).val())
    )

    for loc in @suggestedLocations
      if geonameIds.indexOf(loc.geonameId) isnt -1
        allLocations.push(loc)

    if allLocations.length
      Meteor.call("addEventLocations", @userEventId, allLocations, (error, result) ->
        Modal.hide(template)
      )
    else
      Modal.hide(template)
