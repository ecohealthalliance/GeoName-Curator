Template.event.rendered = ->
  checkPosition = ->
    if($(this.$element).offset().top - $(window).scrollTop() < 150)
      'bottom'
    else
      'top'
  makeTemplate = (className) ->
    template:
      """<div class="popover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content #{className}"></div><a href="#" class="close-popover"></a></div>"""
  baseOpts =
    viewport:
      selector: 'body'
      padding: 10
    trigger: 'hover'
    placement: checkPosition
    animation: true
    delay:
      show: 250
      hide: 400
  $('[data-toggle="popover"]').popover(_.extend(baseOpts, makeTemplate('')))
  $('[data-toggle="popover-quote"]').popover(_.extend(baseOpts, makeTemplate('quote-text')))
  return

formatDate = (dateString) ->
  if dateString
    if dateString.length < 7
      dateString
    else
      year = dateString.substring(0, 4)
      month = parseInt(dateString.substring(5, 7), 10) - 1
      months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
      "#{months[month]} #{year}"

Template.event.helpers
  isEID: ->
    @event?.eidVal is "1"

  simpleTitle: ->
    @eventNameVal.replace(/\(([^)]+)\)/, '')
  displayDates: ->
    if @startDateISOVal isnt "Not Found"
      startDate = @startDateISOVal
    if @endDateISOVal isnt "Not Found"
      endDate = @endDateISOVal

    if startDate
      formatDate startDate
    else if !startDate and endDate
      formatDate endDate
    else
      "Date not found"

  pluralizeLocation: (locations) ->
    if locations.length > 1
      "Locations"
    else
      "Location"

  locationList: (locations) ->
    locations?.map (location) ->
      if location.fieldUsed is 'emergenceHospitalVal'
        "#{location.emergenceHospitalVal}, #{location.locationCityVal}, #{location.locationNationVal}"
      else if location.fieldUsed is 'locationCityVal'
        "#{location.locationCityVal}, #{location.locationNationVal}"
      else if location.fieldUsed is 'locationSubnationalRegionVal'
        "#{location.locationSubnationalRegionVal}, #{location.locationNationVal}"
      else if location.fieldUsed is 'locationNationVal'
        "#{location.locationNationVal}"
      else
        "Location Not Found"

Template.facts.helpers
  icons: ->
    @eventTransmissionVal.split(',').map (icon) ->
      icon = icon.trim()
      if icon is 'Not Found' or icon is ''
        description = 'Transmission method not found'
        fullName = 'Not Found: ' + description
        icon = 'unknown'
      else
        description = @grid.Fields.findOne({"displayName": "Event Transmission"})['dropdownExplanations'][icon]
        fullName = icon.charAt(0).toUpperCase()+icon.substr(1)+': ' + description
      className: "type-"+icon.split(" ")[0].toLowerCase()
      fullName: fullName

getVal = (key, object) ->
  object[key]

Template.registerHelper 'getDescription', (event, field) ->
  info = grid.Fields.findOne({"spreadsheetName": field})
  vals = getVal(info.spreadsheetName, event).trim().split(", ")
  explanations = ("#{val}: #{info.dropdownExplanations[val]}" for val in vals when info.dropdownExplanations[val]).join("; ")
  if explanations
    "#{info.description} (#{explanations})"
  else
    info.description

Template.event.events
  'mouseleave [data-toggle]': (e) ->
    $(e.target).popover('hide')
