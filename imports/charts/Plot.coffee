Axes = require '/imports/charts/Axes.coffee'
Tooltip = require '/imports/charts/Tooltip.coffee'
Zoom = require '/imports/charts/Zoom.coffee'

MINIMUM_PLOT_HEIGHT = 300

class Plot
  ###
  # Plot - creates a new instance of a plot
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
  ###
  constructor: (options) ->
    @options = options
    @drawn = false
    @filters = {}
    @

  ###
  # setDimensions - method to set the dimensions of the plot based on the current window
  ###
  setDimensions: () ->
    @margins = @options.margins || {left: 40, right: 20, top: 20, bottom: 40}
    @width = @options.width || document.getElementById(@options.containerID).offsetWidth - (@margins.left + @margins.right);
    @height = @options.height || Plot.aspectRatio() * @width
    if @height < MINIMUM_PLOT_HEIGHT
      @height = MINIMUM_PLOT_HEIGHT
    @viewBoxWidth = @width + @margins.left + @margins.right
    @viewBoxHeight = @height + @margins.top + @margins.bottom
    @

  ###
  # update - update the width and height attributes of the root and container
  #  elements. then call update on the plot axes
  #
  # @param {array} data, an array of {object} for each marker
  # @returns {object} this
  ###
  update: (data) ->
    @setDimensions()
    @root
      .attr('width', @viewBoxWidth)
      .attr('height', @viewBoxHeight)
    @container
      .attr('width', @width)
      .attr('height', @height)
      .attr('transform', "translate(#{@margins.left}, #{@margins.top})")
    @axes.update(data)
    @


  ###
  # init - method to initialize the plot, allows the plot to be re-initialized
  #  on resize while keeping the current plot data in memory
  #
  # @returns {object} this
  ###
  init: () ->
    # dimensions of the plot
    @setDimensions()

    # should we scale the svg by aspectRatio?
    scale = @options.scale || false

    # the root elment of the plot
    if scale
      @root = d3.select("\##{@options.containerID}").append('svg')
        .attr('viewBox', "0 0 #{@viewBoxWidth} #{@viewBoxHeight}")
        .attr('preserveAspectRatio','xMinYMin meet')
    else
      @root = d3.select("\##{@options.containerID}").append('svg')
        .attr('width', @viewBoxWidth)
        .attr('height', @viewBoxHeight)
    @root.style('opacity', 0)

    # the container of the plot
    @container = @root.append('g')
      .attr('class', @options.svgContainerClass)
      .attr('width', @getWidth())
      .attr('height', @getHeight())
      .attr('transform', "translate(#{@margins.left}, #{@margins.top})")

    # the axes of the plot
    @axes = new Axes(@, @options)

    # add the default filter by axes domain
    @addFilter('_domain', (d) ->
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

    # the tooltip of the plot
    @tooltip = new Tooltip(@, @options)

    # is zoom enabled?
    zoomEnabled = @options.zoom || false
    if zoomEnabled
      @zoom = new Zoom(@, @options)

    # an svg group of the markers
    @markers = @container.append('g')
      .attr('class', 'scatterPlot-markers')
      .attr('transform', "translate(#{@margins.left}, 0)")

    # return
    @

  ###
  # draw - draws the markers on the plot
  #
  # @note this will automatically show/hide a warning message if the data
  # is empty. Do not call super() to override this behavior.
  #
  # @param {array} data, an array of {object} for each marker
  ###
  draw: (data) ->
    if !@drawn
      @drawn = true
      @root.transition().style('opacity', 1)
    if typeof data != 'undefined'
      if data.length <= 0
        @showWarn()
        return
    @removeWarn()

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
  # showWarn - shows a warning message in the center of the plot
  #
  # @param {string} m, the message to display
  #
  # @return {object} this
  ###
  showWarn: (m) ->
    if typeof m == 'undefined'
      m = 'No data to display'
    if @warn
      @removeWarn()
    @warn = @container.append('g')
      .style('opacity', 0)
      .attr('class', 'scatterPlot-warn')
    text = @warn.append('text')
      .attr('text-anchor', 'middle')
      .attr('x', @width / 2)
      .attr('y', @getHeight() / 2)
      .text(m)
    @warn.transition().style('opacity', 1)
    @

  ###
  # removeWarn - removes the warning message from the plot
  #
  # @return {object} this
  ###
  removeWarn: () ->
    if @warn
      @warn.remove()
    @

  ###
  # remove - removes the plot from the DOM and any event listeners
  #
  # @return {object} this
  ###
  remove: () ->
    @zoom.remove()
    @tooltip.remove()
    @axes.remove()
    @markers.remove()
    @container.remove()
    @root.remove()

  ###
  #  destroy - destroys the plot and any associated elements
  ###
  destroy: () ->
    @remove()
    @zoom = null
    @tooltip = null
    @axes = null
    @markers = null
    @container = null
    @root = null
    @resizeHandler = null

  ###
  # addFilter - add a filter to the plot
  #
  # @param {string} name, the name of the filter
  # @param {function} fn, the function to be applied to the data
  # @return {object} this
  ###
  addFilter: (name, fn) ->
    @filters[name] = _.bind(fn, @)
    @

  ###
  # removeFilter - removes a filter from the plot
  #
  # @param {string} name, the name of the filter
  # @return {object} this
  ###
  removeFilter: (name) ->
    if @filters[name] != 'undefined'
      delete @filters[name]
    @

  ###
  # applyFilters - apply any filters to the plot
  #
  # @returns {array} filtered, the filtered data
  ###
  applyFilters: () ->
    filtered = []
    filters = @filters
    if @data
      filtered = @data.filter (d) ->
        valid = true
        keys = Object.keys(filters)
        i = 0
        keysLen = keys.length
        while i < keysLen
          key = keys[i++]
          f = filters[key](d)
          if typeof f == 'undefined'
            valid = false
            break
        if valid
          return d
    return filtered

  ###
  # getData - return the current data array
  #
  # @return {array} data, the current data array (markers) with filters applied
  ###
  getData: () ->
    if @data
      return @applyFilters()
    else
      return []

# find the view port aspect ratio
#
# @return {number} aspectRatio
Plot.aspectRatio = () ->
  $(window).height() / $(window).width()


module.exports = Plot
