class RectMarker
  ###
  # RectMarker
  #
  # @param {object} options, the options used to construct the RectMarker
  # @param {number} options.x, the value for x position
  # @param {number} options.y, the value for y position
  # @param {number} options.w, the value for the width
  # @param {number} options.h, the value for the height
  # @param {string} options.f, the fill of the marker
  # @param {number} options.o, the opacity of the marker
  # @param {object} options.meta, the optional meta data associated with the marker (e.g. used in the Tooltip)
  #
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

RectMarker.createFromIncident = (incident) ->
  if typeof incident == 'undefined'
    return
  if typeof incident.dateRange != 'object'
    return
  m = {}
  m.meta = {}
  x = moment(incident.dateRange.start).hours(0).valueOf()
  if x <= 0
    return
  w = moment(incident.dateRange.end).valueOf()
  if w <= 0
    return
  m.x = x
  m.w = w
  y = 0
  if incident.cases
    y += incident.cases
  if incident.deaths
    y += incident.deaths
  m.y = y
  if incident.locations.length > 0
    m.meta.location = incident.locations[0].name
  marker = new RectMarker(m)
  return marker


module.exports = RectMarker
