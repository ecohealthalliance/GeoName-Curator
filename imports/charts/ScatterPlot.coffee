Axes = require '/imports/charts/Axes.coffee'

class ScatterPlot
  ###
  # ScatterPlot
  #
  # constructs the root SVG element to contain the ScatterPlot
  #
  # @param {object} options, the options to create a ScatterPlot
  # @param {string} containerID, the id of the ScatterPlot container div
  # @param {string} svgContentClass, the desired class of the constructed svg element
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
  ###
  constructor: (options) ->
    @height = options.height || 400
    @margins = options.margins || {left: 40, right: 20, top: 20, bottom: 40}
    @width = options.width || document.getElementById(options.containerID).offsetWidth - (@margins.left + @margins.right);
    @data = options.data || [
      {x: 0, y: 3, w: 4}, {x: 11, y: 31, w: 1}, {x: 15, y: 45, w: 2},
      {x: 1, y: 3, w: 4}, {x: 12, y: 31, w: 1}, {x: 14, y: 45, w: 2}
      {x: 2, y: 3, w: 4}, {x: 13, y: 31, w: 1}, {x: 13, y: 45, w: 2}
    ]

    # the root elment of the plot
    @root = d3.select("\##{options.containerID}").append('svg')
      .attr('width', @width + @margins.left + @margins.right)
      .attr('height', @height + @margins.top + @margins.bottom)
      .append('g')
      .attr('transform', "translate(#{@margins.left}, #{@margins.top})")

    # an svg group of the scatterPlot-rect-markers
    @markers = @root.append('g')
      .attr('class', 'scatterPlot-rect-markers')
      .attr('transform', "translate(#{@margins.left}, 0)")

    # setup the scale proportional to the size of the data excluding margins
    @xScale = d3.scale.linear().domain([0, 25]).range([0, @getWidth()])
    @yScale = d3.scale.linear().domain([0, 50]).range([@getHeight(), 0])

    # iterate of the data to create the markers
    @data.forEach (d) =>
      @_addRectMarker(d.x, d.y, d.w , 5, '#345e7e', .2)

    # the axes of the plot
    @axes = new Axes(@, {
      x: {
        title: 'Time',
        type: 'datetime',
      },
      y: {
        title: 'Incidents',
        type: 'numeric',
      },
    })
    @

  ###
  # getWidth
  #
  # @return {number} width (excluding margins) for the root svg
  ###
  getWidth: () ->
    return @width - (@margins.left + @margins.right)

  ###
  # getHeigth
  #
  # @return {number} width (excluding margins) for the root svg
  ###
  getHeight: () ->
    return @height - (@margins.top + @margins.bottom)

  ###
  # addRectMarker
  #
  # adds a rectangular marker
  #
  # @param {number} x, the x coordinate of the rect (lower left)
  # @param {number} y, the y coordinate of the rect (lower left)
  # @param {number} w, the width of the rect
  # @param {number} h, the height of the rect
  # @param {string} f, the hex color code to fill
  # @param {number} o, the opacity of the fill
  #
  # @returns {object} this, returns itself for chaining
  ###
  _addRectMarker: (x, y, w, h, f, o) ->
    @markers.append('rect')
      .attr('x', @xScale(x))
      .attr('y', @yScale(y))
      .attr('width', @xScale(w))
      .attr('height', @getHeight() - @yScale(2))
      .style('fill', f)
      .style('opacity', o)
    @

module.exports = ScatterPlot
