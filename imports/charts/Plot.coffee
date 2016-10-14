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

    # the container of the plot
    @container = @root.append('g')
      .attr('class', @options.svgContainerClass)
      .attr('width', @getWidth())
      .attr('height', @getHeight())
      .attr('transform', "translate(#{@margins.left}, #{@margins.top})")

    # the axes of the plot
    @axes = new Axes(@, @options)

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
    mSize = m.split('').length;
    @warn = @root.append('g')
      .attr('class', 'scatterPlot-warn')
      .attr('transform', "translate(#{@getWidth() / 2 - mSize}, #{@getHeight() / 2})")
    @warn.append('text')
      .text(m)
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

# find the view port aspect ratio
#
# @return {number} aspectRatio
Plot.aspectRatio = () ->
  $(window).height() / $(window).width()

module.exports = Plot
