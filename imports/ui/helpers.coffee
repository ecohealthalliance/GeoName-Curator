formatLocation = require '/imports/formatLocation.coffee'

UI.registerHelper 'formatLocation', (location)->
  return formatLocation(location)

@pluralize = (word, count) ->
  if Number(count) isnt 1
    word += "s"
  "#{count} #{word}"

formatDateRange = (dateRange, readable)->
  dateFormat = "MMM D, YYYY"
  if dateRange.type is "day"
    if dateRange.cumulative
      return "before " + moment(dateRange.end).format(dateFormat)
    else
      if readable
        return "on " + moment(dateRange.start).format(dateFormat)
      else
        return moment(dateRange.start).format(dateFormat)
  else if dateRange.type is "precise"
    if readable
      return "between " + moment(dateRange.start).format(dateFormat) + " and " + moment(dateRange.end).format(dateFormat)
    else
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

  result = """
    <span>#{incidentDescription}</span> in <span>#{formattedLocations}</span>
  """
  if @dateRange
    result += "<span> #{formatDateRange(@dateRange, true)}</span>"
  Spacebars.SafeString result

UI.registerHelper 'formatDate', (date) ->
  moment(date).format("MMM DD, YYYY")
