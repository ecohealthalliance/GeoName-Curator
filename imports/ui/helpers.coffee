formatLocation = require '/imports/formatLocation.coffee'

UI.registerHelper 'formatLocation', (location)->
  return formatLocation(
    name: location.displayName
    admin1Name: location.subdivision
    countryName: location.countryName
  )

pluralize = (word, count) ->
  if Number(count) isnt 1
    word += "s"
  "#{count} #{word}"

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

UI.registerHelper 'incidentToText', (incident) ->
  if @cases
    incidentDescription = pluralize("case", @cases)
  else if @deaths
    incidentDescription = pluralize("death", @deaths)
  else if @specify
    incidentDescription = @specify
  if @locations.length < 2
    formattedLocations = formatLocation(@locations[0])
  else
    formattedLocations = (
      @locations.map(formatLocation).slice(0, -1).join(", ") +
      ", and " + formatLocation(@locations.slice(-1)[0])
    )

  result = "#{incidentDescription} in #{formattedLocations}"
  if @timeRange
    result += " #{formatTimeRange(@timeRange)}"
  result

UI.registerHelper 'formatDate', (date) ->
  moment(date).format("MMM DD, YYYY")
