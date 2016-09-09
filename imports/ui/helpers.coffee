formatLocation = require '/imports/formatLocation.coffee'
UI.registerHelper 'formatLocation', (location)->
  return formatLocation(location)

formatTimeRange = ({start, end})->
  if start and end
    duration = moment.duration(moment(end).diff(start))
    if duration.asHours() > 24
      "from " + moment(start).format("MMM Do YY") + " to " + moment(end).format("MMM Do YY")
    else if duration.asHours() > 1
      "on " + moment(start).format("MMM Do YY")
    else
      "on " + moment(start).format("MMM Do YY, h a")
  else if start
    "after " + moment(start).format("MMM Do YY")
  else if end
    "before " + moment(end).format("MMM Do YY")
  else
    ""

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
  return "#{incidentDescription} in #{formattedLocations} #{formatTimeRange(@timeRange)}"
