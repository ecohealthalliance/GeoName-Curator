import d3 from 'd3'

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
    @plot = plot
    @options = options || {}
    @axes = axes
    @init()
    #return
    @

  ###
  # init - initialize the x,y grid lines for a plot
  ###
  init: () ->
    # x
    @xGrid = d3.axisBottom().scale(@axes.xScale).tickFormat('').tickSize((@plot.getHeight()) * -1, 0, 0)
    @xGroup = @plot.container.insert('g', ':first-child')
      .attr('class', 'grid')
      .attr('transform', "translate(#{@plot.margins.left}, #{@plot.getHeight()})")
      # use the opacity from the stylesheet
      .attr('opacity', null)
      .call(@xGrid)
    # y
    @yGrid = d3.axisLeft().scale(@axes.yScale).tickFormat('').tickSize((@plot.getWidth()) * -1, 0, 0)
    @yGroup = @plot.container.insert('g', ':first-child')
      .attr('class', 'grid')
      .attr('transform', "translate(#{@plot.margins.left}, 0)")
      # use the opacity from the stylesheet
      .attr('opacity', null)
      .call(@yGrid)

  ###
  # remove - removed the grid lines from the plot
  ###
  remove: () ->
    @xGroup.remove()
    @yGroup.remove()


module.exports = Grid
