formatLocation = (name, sub, country) ->
  text = name
  if sub
    text += ", " + sub
  if country
    text += ", " + country
  return text

Template.locationSelect2.onRendered ->
  $(document).ready(() ->
    $("#location-select2").select2({
      multiple: true
      placeholder: "Search for locations..."
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

Template.location.helpers
  formatLocation: (location) ->
    return formatLocation(location.displayName, location.subdivision, location.countryName)

Template.locationList.events
  "click #add-locations": (event, template) ->
    $new = $("#location-select2")
    allLocations = []
    
    for option in $new.select2("data")
      allLocations.push({
        geonameId: option.item.geonameId,
        name: option.item.name,
        displayName: option.item.toponymName,
        countryName: option.item.countryName,
        subdivision: option.item.adminName1,
        latitude: option.item.lat,
        longitude: option.item.lng
      })
    
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