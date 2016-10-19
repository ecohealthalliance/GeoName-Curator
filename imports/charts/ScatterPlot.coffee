Plot = require '/imports/charts/Plot.coffee'

MINIMUM_MARKER_WIDTH = 10
MINIMUM_MARKER_HEIGHT = 10

class ScatterPlot extends Plot
  ###
  # ScatterPlot - constructs the root SVG element to contain the ScatterPlot
  #
  # @param {object} options, the options to create a ScatterPlot
  # @param {string} containerID, the id of the ScatterPlot container div
  # @param {string} svgcontainerClass, the desired class of the constructed svg element
  # @param {object} tooltip,
  # @param {number} tooltip.opacity, the background opacity for the tooltip
  # @param {object} tooltip.template, the compiled template
  # @param {boolean} scale, scale the svg on window resize @default false
  # @param {boolean} resize, resize the svg on window resize @default true
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
    @init()
    @

  ###
  # init - method to set/re-set the resizeHandler
  #
  # @returns {object} this
  ###
  init: () ->
    super()
    resizeEnabled = @options.resize || true
    if resizeEnabled
      @resizeHandler = _.debounce(_.bind(@resize, this), 500)
      window.addEventListener('resize', @resizeHandler)

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
  # @returns {object} this
  ###
  draw: (data) ->
    super(data)
    if data
      @data = data

    # filter the data is withing the current domain of the axes (necessary
    # when zoom is enabled)
    filtered = _.filter(@data, (d) =>
      x1 = @axes.xScale.domain()[0]
      if x1 instanceof Date
        x1 = x1.getTime()
      x2 = @axes.xScale.domain()[1]
      if x2 instanceof Date
        x2 = x2.getTime()
      y1 = @axes.yScale.domain()[0]
      y2 = @axes.yScale.domain()[1]
      if ((d.x >= x1 && d.x <= x2) && (d.y >= y1 && d.y <= y2))
        return d
    )

    @markers.selectAll('.marker').data(filtered).enter().append('rect')
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
  # update the dimensions of the plot (axes, gridlines, then redraw)
  #
  # @param {array} data, an array of {object} for each marker
  # @returns {object} this
  ###
  update: (data) ->
    if data
      @data = data
    super(data)
    @redraw(data)
    @

  ###
  # clears the data, updates the axes, then redraws
  #
  # @returns {object} this
  ###
  redraw: (draw) ->
    @clear().draw(draw)
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
    @update()
    @

  ###
  # resetZoom - resets the zoom of the axes
  ###
  resetZoom: () ->
    if !@data || @data.length <= 0
      return
    if @zoom
      @zoom.reset()


module.exports = ScatterPlot
