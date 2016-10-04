Grid = require '/imports/charts/Grid.coffee'

class Axes
  ###
  # Axes
  #
  # constructs 2d cartesian axes, appends to the content SVG element of the plot
  #
  # @param {object} plot, the plot to append the axis
  # @param {object} options, the properties for the axis
  # @param {boolean} grid, should the grid be displayed?
  # X axis properties
  # @param {object} options.axes.x, the properties for x axis
  # @param {string} options.axes.x.title, the title of the x axis
  # @param {string} options.axes.x.type, the datatype of the x axis {numeric, datetime}
  # Y axis properties
  # @param {object} options.axes.y, the properties for y axis
  # @param {string} options.axes.y.title, the title of the y axis
  # @param {string} options.axes.y.type, the datatype of the y axis {numeric, datetime}
  #
  # @returns {object} this, returns self
  #
  # example usage:
  #  with an instance of a plot:
    ```
    axes = new Axes(plot, {
      axes: {
        grid: true,
        x: {
          title: 'Time',
          type: 'datetime',
          minMax: [1443371126, 1474993537]
        },
        y: {
          title: 'Incidents',
          type: 'numeric',
          minMax: [0, 100]
        },
      }
    })
    ```
  #
  ###
  constructor: (plot, options) ->
    @options = options
    @axesOpts = options.axes || {x: {title: 'x', type: 'numeric', minMax: [0,100]}, y: {title: 'y', type: 'numeric', minMax: [0, 100]}, grid: true}
    @_buildX(plot)
    @_buildY(plot)
    # the x,y grid lines, requires the axes
    if @axesOpts.grid
      @grid = new Grid(@, plot, @options)
    #return
    @

  ###
  # buildX - build the xScale, xAxis, and append xGroup
  #
  # @param {object} plot, the plot to append the axis group
  ###
  _buildX: (plot) ->
    if @axesOpts.x.type == 'datetime'
      @xScale = d3.time.scale().domain(@axesOpts.x.minMax).range([0, plot.getWidth()]).nice()
    else
      @xScale = d3.scale.linear().domain(@axesOpts.x.minMax).range([0, plot.getWidth()])

    # create the axes from the scale and position
    # xAxis
    if @axesOpts.x.type == 'datetime'
      @xAxis = d3.svg.axis()
        .scale(@xScale)
        .orient('bottom')
        .ticks(10)
        .tickFormat(d3.time.format("%b %d, %Y"))
    else
      @xAxis = d3.svg.axis()
        .scale(@xScale)
        .orient('bottom')
        .ticks(10)

    # append the svg element as a group, store reference
    # xGroup
    if @axesOpts.x.type == 'datetime'
      @xGroup = plot.content.append('g')
        .attr('class', 'scatterPlot-axis')
        .attr('transform', "translate(#{plot.margins.left}, #{plot.getHeight()})")
        .call(@xAxis)
      @xGroup.selectAll('text')
        .style('text-anchor', 'end')
        .attr('dx', '-.8em')
        .attr('dy', '.15em')
        .attr('transform', (d) -> 'rotate(-65)')
      @xGroup.append('text')
        .attr('dx', (plot.width / 2) - ((plot.margins.right + plot.margins.left) / 2))
        .attr('dy', plot.margins.bottom + 30)
        .attr('class', 'scatterPlot-axis-label')
        .style('text-anchor', 'middle')
        .text(@axesOpts.x.title);
    else
      @xGroup = plot.content.append('g')
        .attr('class', 'scatterPlot-axis')
        .attr('transform', "translate(#{plot.margins.left}, #{plot.getHeight()})")
        .call(@xAxis)
      @xGroup.append('text')
        .attr('dx', (plot.width / 2) - ((plot.margins.right + plot.margins.left) / 2))
        .attr('dy', plot.margins.bottom)
        .attr('class', 'scatterPlot-axis-label')
        .style('text-anchor', 'middle')
        .text(@axesOpts.x.title);

  ###
  # buildY - build the yScale, yAxis, and append yGroup
  #
  # @param {object} plot, the plot to append the axis group
  ###
  _buildY: (plot) ->
    @yScale = d3.scale.linear().domain(@axesOpts.y.minMax).range([plot.getHeight(), 0])
    @yAxis = d3.svg.axis()
      .scale(@yScale)
      .orient('left')
    @yGroup = plot.content.append('g')
      .attr('class', 'scatterPlot-axis')
      .attr('transform', "translate(#{plot.margins.left}, 0)")
      .call(@yAxis)
    @yGroup.append('text')
      .attr('transform', 'rotate(-90)')
      .attr('dx', - (plot.height / 2) + ((plot.margins.top + plot.margins.bottom) / 2))
      .attr('dy', - plot.margins.left)
      .attr('class', 'scatterPlot-axis-label')
      .style('text-anchor', 'middle')
      .text(@axesOpts.y.title);


  ###
  # remove - removed the axes groups from the DOM
  ###
  remove: () ->
    @xGroup.remove()
    @yGroup.remove()
    if @grid
      @grid.remove()


module.exports = Axes
