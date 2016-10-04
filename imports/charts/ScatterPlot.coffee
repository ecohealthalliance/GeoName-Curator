Axes = require '/imports/charts/Axes.coffee'
Tooltip = require '/imports/charts/Tooltip.coffee'

MINIMUM_MARKER_WIDTH = 10
MINIMUM_MARKER_HEIGHT = 10

class ScatterPlot
  ###
  # ScatterPlot
  #
  # constructs the root SVG element to contain the ScatterPlot
  #
  # @param {object} options, the options to create a ScatterPlot
  # @param {string} containerID, the id of the ScatterPlot container div
  # @param {string} svgContentClass, the desired class of the constructed svg element
  # @param {function} tooltipTemplate, the compiled template to execute for the tooltip
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
    @options = options
    @init()

  ###
  # init - method to initialize the plot, allows the plot to be re-initialized
  #  on resize while keeping the current plot data in memory
  #
  # @returns {object} this, returns self
  ###
  init: () ->
    scale = @options.scale || false
    resize = @options.resize || true

    @margins = @options.margins || {left: 40, right: 20, top: 20, bottom: 40}
    @width = @options.width || document.getElementById(@options.containerID).offsetWidth - (@margins.left + @margins.right);
    @height = @options.height || ScatterPlot.aspectRatio() * @width
    viewBoxWidth = @width + @margins.left + @margins.right
    viewBoxHeight = @height + @margins.top + @margins.bottom

    # the root elment of the plot
    if scale
      @root = d3.select("\##{@options.containerID}").append('svg')
        .attr('viewBox', "0 0 #{viewBoxWidth} #{viewBoxHeight}")
        .attr('preserveAspectRatio','xMinYMin meet')
    else
      @root = d3.select("\##{@options.containerID}").append('svg')
        .attr('width', viewBoxWidth)
        .attr('height', viewBoxHeight)

    if resize
      @resizeHandler = _.debounce(_.bind(@resize, this), 500)
      window.addEventListener('resize', @resizeHandler)

    @content = @root.append('g')
      .attr('class', 'scatterPlot-content')
      .attr('transform', "translate(#{@margins.left}, #{@margins.top})")

    # the axes of the plot
    @axes = new Axes(@, @options)

    # the tooltip of the plot
    @tooltip = new Tooltip(@, @options)

    # an svg group of the markers
    @markers = @content.append('g')
      .attr('class', 'scatterPlot-markers')
      .attr('transform', "translate(#{@margins.left}, 0)")

    # return
    @

  ###
  # getWidth
  #
  # @return {number} width (excluding margins) for the root svg
  ###
  getWidth: () ->
    @width - (@margins.left + @margins.right)

  ###
  # getHeigth
  #
  # @return {number} width (excluding margins) for the root svg
  ###
  getHeight: () ->
    @height - (@margins.top + @margins.bottom)

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
    window.removeEventListener('resize', @resizeHandler)
    @tooltip.remove()
    @axes.remove()
    @markers.remove()
    @content.remove()
    @root.remove()
    @

  ###
  #  destroy - destroys the plot and any associated elements
  ###
  destroy: () ->
    @remove()
    @tooltip = null
    @axes = null
    @markers = null
    @content = null
    @root = null
    @resizeHandler = null

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
  # showWarn - shows a warning message in the center of the plot
  #
  # @param {string} m, the message to display
  #
  # @return {object} this
  ###
  showWarn: (m) ->
    mSize = m.split('').length;
    @warn = @root.append('g')
      .attr('class', 'scatterPlot-warn')
      .attr('transform', "translate(#{@getWidth() / 2 - mSize}, #{@getHeight() / 2})")
    @warn.append('text')
      .text(m)
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

# find the view port aspect ratio
#
# @return {number} aspectRatio
ScatterPlot.aspectRatio = () ->
  $(window).height() / $(window).width()


module.exports = ScatterPlot
