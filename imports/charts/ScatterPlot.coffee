Plot = require '/imports/charts/Plot.coffee'

MINIMUM_MARKER_WIDTH = 10
MINIMUM_MARKER_HEIGHT = 10

class ScatterPlot extends Plot
  ###
  # ScatterPlot
  #
  # constructs the root SVG element to contain the ScatterPlot
  #
  # @param {object} options, the options to create a ScatterPlot
  # @param {string} containerID, the id of the ScatterPlot container div
  # @param {string} svgcontainerClass, the desired class of the constructed svg element
  # @param {object} tooltip,
  # @param {number} tooltip.opacity, the background opacity for the tooltip
  # @param {object} tooltip.template, the compiled template
  # @param {boolean} scale, scale the svg on window resize @default false
  # @param {boolean} resize, resize the svg on window resize @default true
  #
  # @returns {object} this, returns self
  #
  # example usage:
  #  within your template add
   ```
   <div id="scatterPlot" class="scatterPlot-container">
   ```
  #  within your template helper, construct a new ScatterPlot instance
   ```
  plot = new ScatterPlot(options)
   ```
  #
  # example datetime data:
  ```
    data = [
      {x: 1443380879164, y: 3, w: 1445972879164}, {x: 1467054386392, y: 31, w: 1467659186392}, {x: 1459105926404, y: 15, w: 1469646565130},
      {x: 1443380879164, y: 3, w: 1448654879164}, {x: 1467054386392, y: 31, w: 1468263986392}, {x: 1459105926404, y: 15, w: 1467659365130},
      {x: 1443380879164, y: 3, w: 1451246879164}, {x: 1467054386392, y: 31, w: 1468868786392}, {x: 1459105926404, y: 15, w: 1467918565130},
    ]
  ```
  #
  # example numeric data:
  ```
    data = [
      {x: 0, y: 3, w: 4}, {x: 5, y: 31, w: 9}, {x: 11, y: 45, w: 15},
      {x: 1, y: 3, w: 4}, {x: 5, y: 31, w: 15}, {x: 12, y: 45, w: 14},
      {x: 2, y: 3, w: 4}, {x: 6, y: 31, w: 7}, {x: 12, y: 45, w: 17},
    ]
  ```
  #
  ###
  constructor: (options) ->
    super(options)
    resize = @options.resize || true
    if resize
      @resizeHandler = _.debounce(_.bind(@resize, this), 500)
      window.addEventListener('resize', @resizeHandler)
    @

  ###
  # init - method to set/re-set the resizeHandler
  #
  # @returns {object} this, returns self
  ###
  init: () ->
    super()

    resize = @options.resize || true
    if resize
      @resizeHandler = _.debounce(_.bind(@resize, this), 500)
      window.addEventListener('resize', @resizeHandler)

    zoom = @options.zoom || false
    if zoom
      #
      @bandPos = [-1, -1];
      @zoomArea =
        x1: @options.axes.x.minMax[0],
        y1: @options.axes.y.minMax[0],
        x2: @options.axes.x.minMax[1],
        y2: @options.axes.y.minMax[1]
      @drag = d3.behavior.drag();
      @zoomBand = @container.append('rect')
        .attr('width', 0)
        .attr('height', 0)
        .attr('x', 0)
        .attr('y', 0)
        .attr('class', 'zoomBand')
      @zoomOverlay = @container.append('rect')
        .attr('width', @getWidth() - 10)
        .attr('height', @getHeight())
        .attr('class', 'zoomOverlay')
        .call(@drag);
      @resetZoomGroup = @container.append('g').attr('class', 'scatterPlot-resetZoom')
      @resetZoomBtn = @resetZoomGroup.append('rect')
        .attr('class', 'resetZoomBtn')
        .attr('width', 75)
        .attr('height', 20)
        .attr('x', @getWidth() + @margins.right)
        .attr('y', @getHeight() + (@margins.bottom + 10))
        .on('click', () => @resetZoom())
      @resetZoomGroup.append('text')
        .attr('class', 'resetZoomText')
        .attr('width', 75)
        .attr('height', 20)
        .attr('x', @getWidth() + (@margins.right + 2))
        .attr('y', @getHeight() + (@margins.bottom + 24))
        .text('Reset Zoom');

      self = @
      @drag.on 'drag', () ->
        pos = d3.mouse(@);
        if pos[0] < self.bandPos[0]
          self.zoomBand.attr('transform', "translate(#{pos[0]}, #{self.bandPos[1]})")
        if pos[1] < self.bandPos[1]
          self.zoomBand.attr('transform', "translate(#{pos[0]}, #{pos[1]})")
        if pos[1] < self.bandPos[1] and pos[0] > self.bandPos[0]
          self.zoomBand.attr('transform', "translate(#{self.banPos[0]}, #{pos[1]})")
        if self.bandPos[0] == -1
          self.bandPos = pos;
          self.zoomBand.attr('transform', "translate(#{self.bandPos[0]}, #{self.bandPos[1]})")
        self.zoomBand.transition().duration(1)
          .attr('width', Math.abs(self.bandPos[0] - pos[0]))
          .attr('height', Math.abs(self.bandPos[1] - pos[1]))

      @drag.on 'dragend', () ->
        pos = d3.mouse(@)
        x1 = self.axes.xScale.invert(self.bandPos[0])
        x2 = self.axes.xScale.invert(pos[0])
        if x1 < x2
          self.zoomArea.x1 = x1
          self.zoomArea.x2 = x2
        else
          self.zoomArea.x1 = x2
          self.zoomArea.x2 = x1

        y1 = self.axes.yScale.invert(pos[1]);
        y2 = self.axes.yScale.invert(self.bandPos[1])
        if x1 < x2
          self.zoomArea.y1 = y1
          self.zoomArea.y2 = y2
        else
          self.zoomArea.y1 = y2
          self.zoomArea.y2 = y1

        self.bandPos = [-1, -1];
        self.zoomBand.transition()
          .attr('width', 0)
          .attr('height', 0)
          .attr('x', self.bandPos[0])
          .attr('y', self.bandPos[1])

        # TODO: recalculate domains and zoom
        console.log 'zoom: ', self.zoomArea

  ###
  # resetZoom -
  ###
  resetZoom: () ->
    console.log 'resetZoom: ', @

  ###
  # draw - draw using d3 select.data.enter workflow
  #
  # adds rectangular markers to the plot
  # TODO - refactor so that different types of markers can be drawn, at first
  #  glance this may mean abandoning d3 select.data.enter workflow for a
  #  custom loop.
  #
  # @param {array} data, an array of {object} for each marker
  # @param {number} data.x, the x coordinate of the rect (lower left)
  # @param {number} data.y, the y coordinate of the rect (lower left)
  # @param {number} data.w, the width of the rect
  # @param {number} data.h, the height of the rect
  # @param {string} data.f, the hex color code to fill
  # @param {number} data.o, the opacity of the fill
  ###
  draw: (data) ->
    if typeof data == 'undefined'
      return
    @data = data
    @clear()
    @markers.selectAll('.marker').data(data).enter().append('rect')
      # if the scale is large enough (e.g. the scale is two years and the span
      # x and w is one day), it is possible to have very small width, such as .2,
      # which isn't visible on the plot. therefore the minimum size will be set
      # by MINIMUM_MARKER_WIDTH and MINIMUM_MARKER_HEIGHT
      .attr('class', 'marker')
      .attr('x', (d) =>
        @axes.xScale(d.x)
      )
      .attr('y', (d) =>
        height = d.h
        if height < MINIMUM_MARKER_HEIGHT
          height = MINIMUM_MARKER_HEIGHT
        @axes.yScale(d.y) - height/2
      )
      .attr('width', (d) =>
        width = @axes.xScale(d.w) - @axes.xScale(d.x)
        if width < MINIMUM_MARKER_WIDTH
          width = MINIMUM_MARKER_WIDTH
        width
      )
      .attr('height', (d) ->
        height = d.h
        if height < MINIMUM_MARKER_HEIGHT
          height = MINIMUM_MARKER_HEIGHT
        height
      )
      .style('fill', (d) -> d.f)
      .style('opacity', (d) -> d.o)
      .on('mouseover', (d) =>
        @tooltip.mouseover(d, d3.event.pageX, d3.event.pageY)
      )
      .on('mouseout', (d) =>
        @tooltip.mouseout()
      )
    #return
    @

  ###
  # clear - removes any markers from the plot
  #
  # @return {object} this
  ###
  clear: () ->
    @markers.selectAll('.marker').remove()
    @

  ###
  # remove - removes the plot from the DOM and any event listeners
  #
  # @return {object} this
  ###
  remove: () ->
    super()
    if @resizeHandler
      window.removeEventListener('resize', @resizeHandler)
    @

  ###
  # resize - re-renders the plot
  #
  # @return {object} this
  ###
  resize: () ->
    @remove()
    @init()
    @draw(@data)
    @

###
# maxNumeric - determine the maximum value with padding. Padding is determined
# by the number of digits ^ 10 / 10, unless number of digets == 10 then return
# 10
#
# @param {array} data, an array of positive integers
# @return {number} max
###
ScatterPlot.maxNumeric = (data) ->
  m = _.max(data)
  l = String(m).split('').length
  # if the length of the number is 1, (e.g 0 ... 9) then return 10
  if l == 1
    return 10
  p = (Math.pow(10, l)) / 10
  m + p

###
# getDatetimeUnit - determine the unit of time for padding the axis
#
# @param {object} min, the min moment datetime object
# @param {object} max, the max moment datetime object
# @return {string} the datetime unit {day, week, month}
###
getDatetimeUnit = (min, max) ->
  diff = max.diff(min, 'days')
  unit = 'month' # one of {day, week, month} default is month
  if diff <= 14
    unit = 'day'
  else if diff > 14 and diff <= 183
    unit = 'week'
  unit

###
# maxDatetime - determine the maximum value with padding
#
# @param {array} data, an array of timestamps in milliseconds
# @return {number} max, maximum datetime value
###
ScatterPlot.maxDatetime = (data) ->
  min = moment(_.min(data))
  max = moment(_.max(data))
  unit = getDatetimeUnit(min, max)
  moment(max).add(1, unit).valueOf()

###
# minDatetime - determine the minimum value with padding
#
# @param {array} data, an array of timestamps in milliseconds
# @return {number} min, minimum datetime value
###
ScatterPlot.minDatetime = (data, unit, amount) ->
  min = moment(_.min(data))
  max = moment(_.max(data))
  unit = getDatetimeUnit(min, max)
  moment(min).subtract(1, unit).valueOf()


module.exports = ScatterPlot
