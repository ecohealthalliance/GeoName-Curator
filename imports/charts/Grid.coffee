class Grid
  ###
  # Grid - constructs grids lines for the plot
  #
  # @param {object} axes, the axes to determine xScale, yScale
  # @param {object} plot, the plot to append the axis
  # @param {object} options, the properties for the axis
  # @returns {object} this
  #
  ###
  constructor: (axes, plot, options) ->
    @options = options
    @plot = plot
    @axes = axes
    @init()
    #return
    @

  ###
  # init - initialize the x,y grid lines for a plot
  ###
  init: () ->
    # x
    @xGrid = d3.svg.axis().scale(@axes.xScale).orient('bottom').tickFormat('').tickSize((@plot.getHeight()) * -1, 0, 0)
    @xGroup = @plot.container.insert('g', ':first-child')
      .attr('class', 'grid')
      .attr('transform', "translate(#{@plot.margins.left}, #{@plot.getHeight()})")
      .call(@xGrid)
    # y
    @yGrid = d3.svg.axis().scale(@axes.yScale).orient('left').tickFormat('').tickSize((@plot.getWidth()) * -1, 0, 0)
    @yGroup = @plot.container.insert('g', ':first-child')
      .attr('class', 'grid')
      .attr('transform', "translate(#{@plot.margins.left}, 0)")
      .call(@yGrid)

  ###
  # remove - removed the grid lines from the plot
  ###
  remove: () ->
    @xGroup.remove()
    @yGroup.remove()


module.exports = Grid
