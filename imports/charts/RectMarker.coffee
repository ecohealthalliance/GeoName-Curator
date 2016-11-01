import d3 from 'd3'

MINIMUM_MARKER_WIDTH = 10
MINIMUM_MARKER_HEIGHT = 10

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
  # remove - removes the marker from the DOM
  ###
  remove: () ->
    if @group
      @group.remove()

  ###
  # detached - builds a detached svg group and returns the node
  #
  # @param {object} plot, the plot to which this node will belong
  # @return {object} node, the SVG node to append to the parent during .call()
  ###
  detached: (plot) ->
    if @group
      @remove()

    @group = plot.markers.append('g').attr('id', @id).attr('class', 'marker').remove()
    rect= @group.append('rect')
      # if the scale is large enough (e.g. the scale is two years and the span
      # x and w is one day), it is possible to have very small width, such as .2,
      # which isn't visible on the plot. therefore the minimum size will be set
      # by MINIMUM_MARKER_WIDTH and MINIMUM_MARKER_HEIGHT
      .attr('class', 'marker')
      .attr('x', () =>
        plot.axes.xScale(@x)
      )
      .attr('y', () =>
        height = @h
        if height < MINIMUM_MARKER_HEIGHT
          height = MINIMUM_MARKER_HEIGHT
        plot.axes.yScale(@y) - height/2
      )
      .attr('width', () =>
        width = plot.axes.xScale(@w) - plot.axes.xScale(@x)
        if width < MINIMUM_MARKER_WIDTH
          width = MINIMUM_MARKER_WIDTH
        width
      )
      .attr('height', () =>
        height = @h
        if height < MINIMUM_MARKER_HEIGHT
          height = MINIMUM_MARKER_HEIGHT
        height
      )
      .style('fill', () => @f)
      .style('opacity', () => @o)
      .on('mouseover', () =>
        if plot.tooltip
          plot.tooltip.mouseover(@, d3.event.pageX, d3.event.pageY)
      )
      .on('mouseout', () ->
        if plot.tooltip
          plot.tooltip.mouseout()
      )
    @group.node()


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
    w = moment(incident.dateRange.start).hours(0).add(24, 'hours').valueOf()
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
