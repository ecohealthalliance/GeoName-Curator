class Axes
  ###
  # Axes
  #
  # constructs 2d cartesian axes and appends to the root SVG element of the plot
  #
  # @param {object} plot, the plot to append the axis
  # @param {object} props, the properties for the axis
  # X axis properties
  # @param {object} props.x, the properties for x axis
  # @param {string} props.x.title, the title of the x axis
  # @param {string} props.x.type, the datatype of the x axis {numeric, datetime}
  # Y axis properties
  # @param {object} props.y, the properties for y axis
  # @param {string} props.y.title, the title of the y axis
  # @param {string} props.y.type, the datatype of the y axis {numeric, datetime}
  #
  # @returns {object} this, returns self
  #
  # example usage:
  #  with an instance of a plot:
    ```
    axes = new Axes(plot, {
      x: {
        title: 'Time',
        type: 'datetime',
      },
      y: {
        title: 'Incidents',
        type: 'numeric',
      },
    })
    ```
  #
  ###
  constructor: (plot, props) ->
    # create the axes from the scale and position
    @x = d3.svg.axis()
      .scale(plot.xScale)
      .orient('bottom')
      .tickPadding(10)
    @y = d3.svg.axis()
      .scale(plot.yScale)
      .orient('left')
      .tickPadding(10)
    plot.root.append('g')
      .attr('class', 'scatterPlot-axis')
      .attr('transform', "translate(#{plot.margins.left}, #{plot.getHeight()})")
      .call(@x).append('text')
      .attr('x', (plot.width / 2) - ((plot.margins.right + plot.margins.left) / 2))
      .attr('y', plot.margins.bottom)
      .attr('class', 'scatterPlot-axis-label')
      .style('text-anchor', 'middle')
      .text(props.x.title);
    plot.root.append('g')
      .attr('class', 'scatterPlot-axis')
      .attr('transform', "translate(#{plot.margins.left}, 0)")
      .call(@y).append('text')
      .attr("transform", "rotate(-90)")
      .attr('x', - (plot.height / 2) + ((plot.margins.top + plot.margins.bottom) / 2))
      .attr('y', - plot.margins.left)
      .attr('class', 'scatterPlot-axis-label')
      .style('text-anchor', 'middle')
      .text(props.y.title);
    @


module.exports = Axes
