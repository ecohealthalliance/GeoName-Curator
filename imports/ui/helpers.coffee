formatLocation = require '/imports/formatLocation.coffee'
UI.registerHelper 'formatLocation', (location)->
  return formatLocation(
    name: location.displayName
    admin1Name: location.subdivision
    countryName: location.countryName
  )

formatDateRange = (dateRange)->
  dateFormat = "MMM D, YYYY"
  if dateRange.type is "day"
    if dateRange.cumulative
      return "Before " + moment(dateRange.end).format(dateFormat)
    else
      return moment(dateRange.start).format(dateFormat)
  else if dateRange.type is "precise"
    return moment(dateRange.start).format(dateFormat) + " - " + moment(dateRange.end).format(dateFormat)
  return ""

UI.registerHelper 'formatDateRange', (dateRange)->
  return formatDateRange(dateRange)

UI.registerHelper 'incidentToText', (incident)->
  console.log incident
  if @cases
    incidentDescription = "#{@cases} death" + if @deaths > 1 then "s" else ""
  else if @deaths
    incidentDescription = "#{@deaths} death" + if @deaths > 1 then "s" else ""
  else if @specify
    incidentDescription = @specify
  if @locations.length < 2
    formattedLocations = formatLocation(@locations[0])
  else
    formattedLocations = (
      @locations.map(formatLocation).slice(0, -1).join(", ") +
      ", and " + formatLocation(@locations.slice(-1)[0])
    )
  return "#{incidentDescription} in #{formattedLocations} #{formatDateRange(@dateRange)}"
