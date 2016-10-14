class RectMarker
  ###
  # RectMarker - a rectangular marker
  #
  # @param {object} options, the options used to construct the RectMarker
  # @param {number} options.x, the value for x position
  # @param {number} options.y, the value for y position
  # @param {number} options.w, the value for the width
  # @param {number} options.h, the value for the height
  # @param {string} options.f, the fill of the marker
  # @param {number} options.o, the opacity of the marker
  # @param {object} options.meta, the optional meta data associated with the marker (e.g. used in the Tooltip)
  # @return {object} this
  ###
  constructor: (options) ->
    @x = options.x
    @y = options.y
    @w = options.w
    @h = options.h || 10
    @f = options.f || '#345e7e'
    @o = options.o || 0.3
    @meta = options.meta || {}

    #return
    @

###
# createFromIncident - method to construct a RectMarker from an incident
#
# @param {object} incident, the incident used to create a marker
# @return {object} RectMarker, the marker that is created
###
RectMarker.createFromIncident = (incident) ->
  if typeof incident == 'undefined'
    return
  if typeof incident.dateRange != 'object'
    return
  m = {
    meta: {}
  }
  x = -1
  w = -1
  if incident.dateRange.type == 'precise'
    x = moment(incident.dateRange.start).valueOf()
    w = moment(incident.dateRange.end).valueOf()
  else if incident.dateRange.type == 'day'
    x = moment(incident.dateRange.start).hours(0).valueOf()
    w = moment(incident.dateRange.end).hours(0).valueOf()
  if x <= 0 || w <= 0
    return
  m.x = x
  m.w = w
  y = 0
  if typeof incident.cases != 'undefined'
    m.meta.type = 'case'
    m.f = '#345e7e'
    y += incident.cases
  if typeof incident.deaths != 'undefined'
    m.meta.type = 'death'
    m.f = '#f07382'
    y += incident.deaths
  m.y = y
  if incident.locations.length > 0
    m.meta.location = incident.locations[0].name
  if incident.dateRange.cumulative
    m.meta.cumulative = true
  new RectMarker(m)


module.exports = RectMarker
