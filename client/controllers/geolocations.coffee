formatLocation = require '/imports/formatLocation.coffee'

Template.location.helpers
  formatDate: (date) ->
    return moment(date).format("MMM D, YYYY")

Template.location.events
  "click .proMedLink": (event, template) ->
    anchorNode = event.currentTarget
    url = anchorNode.getAttribute 'uri'
    if url
      $('#proMedIFrame').attr('src', url)
      $('#proMedURL').attr('href', url)
      $('#proMedURL').text(url)
      $('#proMedModal').modal("show")

Template.locationModal.helpers
  locationOptionText: (location) ->
    return formatLocation(
      name: location.displayName
      admin1Name: location.subdivision
      countryName: location.countryName
    )

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
      Meteor.call("addEventLocations", @userEventId, [@article], allLocations, (error, result) ->
        Modal.hide(template)
      )
    else
      Modal.hide(template)
