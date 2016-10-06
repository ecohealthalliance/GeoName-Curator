class Grid
  ###
  # Grid
  #
  # constructs grids lines for the plot
  #
  # @param {object} axes, the axes to determine xScale, yScale
  # @param {object} plot, the plot to append the axis
  # @param {object} options, the properties for the axis
  # @returns {object} this, returns self
  #
  ###
  constructor: (axes, plot, options) ->
    @options = options
    @_buildX(axes, plot)
    @_buildY(axes, plot)
    #return
    @

  ###
  # buildX - build the x grid lines
  #
  # @param {object} axes, the axes to determine xScale, yScale
  # @param {object} plot, the plot to append the axis group
  ###
  _buildX: (axes, plot) ->
    @xGrid = d3.svg.axis().scale(axes.xScale).orient('bottom').tickFormat('').tickSize((plot.getHeight()) * -1, 0, 0)
    @xGroup = plot.container.append('g')
      .attr("class", "grid")
      .attr('transform', "translate(#{plot.margins.left}, #{plot.getHeight()})")
      .call(@xGrid)

  ###
  # buildY - build the y grid lines
  #
  # @param {object} axes, the axes to determine xScale, yScale
  # @param {object} plot, the plot to append the axis group
  ###
  _buildY: (axes, plot) ->
    @yGrid = d3.svg.axis().scale(axes.yScale).orient('left').tickFormat('').tickSize((plot.getWidth()) * -1, 0, 0)
    @yGroup = plot.container.append('g')
      .attr("class", "grid")
      .attr('transform', "translate(#{plot.margins.left}, 0)")
      .call(@yGrid)

  ###
  # remove - removed the axes groups from the DOM
  ###
  remove: () ->
    @xGroup.remove()
    @yGroup.remove()


module.exports = Grid
