Grid = require '/imports/charts/Grid.coffee'

class Axes
  ###
  # Axes
  #
  # constructs 2d cartesian axes, appends to the container SVG element of the plot
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
    @plot = plot
    @options = options
    @axesOpts = options.axes || {x: {title: 'x', type: 'numeric', minMax: [0,100]}, y: {title: 'y', type: 'numeric', minMax: [0, 100]}, grid: true}
    @init()

  ###
  # init - initialize the plot x,y axes
  #
  # @param {array} xDomain, the zoom xDomain or undefined
  # @param {array} yDomain, the zoom yDomain or undefined
  ###
  init: (xDomain, yDomain) ->
    # xScale
    if @axesOpts.x.type == 'datetime'
      if xDomain
        @xScale = d3.time.scale().domain(xDomain).range([0, @plot.getWidth()]).nice()
      else
        @xScale = d3.time.scale().domain(@axesOpts.x.minMax).range([0, @plot.getWidth()]).nice()
    else
      if xDomain
        @xScale = d3.scale.linear().domain(xDomain).range([0, @plot.getWidth()])
      else
        @xScale = d3.scale.linear().domain(@axesOpts.x.minMax).range([0, @plot.getWidth()])

    # xAxis
    if @axesOpts.x.type == 'datetime'
      @xAxis = d3.svg.axis()
        .scale(@xScale)
        .orient('bottom')
        .ticks(10)
        .tickFormat(d3.time.format(@formatDate()))
    else
      @xAxis = d3.svg.axis()
        .scale(@xScale)
        .orient('bottom')
        .ticks(10)

    # xGroup
    if @axesOpts.x.type == 'datetime'
      @xGroup = @plot.container.append('g')
        .attr('class', 'x scatterPlot-axis')
        .attr('transform', "translate(#{@plot.margins.left}, #{@plot.getHeight()})")
        .call(@xAxis)
      @xGroup.selectAll('text')
        .style('text-anchor', 'end')
        .attr('dx', '-.8em')
        .attr('dy', '.15em')
        .attr('transform', (d) -> 'rotate(-65)')
      @xGroup.append('text')
        .attr('class', 'scatterPlot-axis-label')
        .attr('dx', (@plot.width / 2) - ((@plot.margins.right + @plot.margins.left) / 2))
        .attr('dy', @plot.margins.bottom + 30)
        .style('text-anchor', 'middle')
        .text(@axesOpts.x.title)
    else
      @xGroup = @plot.container.append('g')
        .attr('class', 'scatterPlot-axis')
        .attr('transform', "translate(#{@plot.margins.left}, #{@plot.getHeight()})")
        .call(@xAxis)
      @xGroup.append('text')
        .attr('dx', (@plot.width / 2) - ((@plot.margins.right + @plot.margins.left) / 2))
        .attr('dy', @plot.margins.bottom)
        .attr('class', 'scatterPlot-axis-label')
        .style('text-anchor', 'middle')
        .text(@axesOpts.x.title)

    # yScale
    if yDomain
      @yScale = d3.scale.linear().domain(yDomain).range([@plot.getHeight(), 0])
    else
      @yScale = d3.scale.linear().domain(@axesOpts.y.minMax).range([@plot.getHeight(), 0])

    # yAxis
    @yAxis = d3.svg.axis()
      .scale(@yScale)
      .orient('left')

    # yGroup
    @yGroup = @plot.container.append('g')
      .attr('class', 'y scatterPlot-axis')
      .attr('transform', "translate(#{@plot.margins.left}, 0)")
      .call(@yAxis)
    @yGroup.append('text')
      .attr('transform', 'rotate(-90)')
      .attr('dx', - (@plot.height / 2) + ((@plot.margins.top + @plot.margins.bottom) / 2))
      .attr('dy', - @plot.margins.left)
      .attr('class', 'scatterPlot-axis-label')
      .style('text-anchor', 'middle')
      .text(@axesOpts.y.title)


    # the x,y grid lines, requires the instance of the axes
    if @axesOpts.grid
      @grid = new Grid(@, @plot, @options)

  ###
  # update - update the x,y axes using the zoom domain
  ###
  update: () ->
    @remove()
    @init(@xScale.domain(), @yScale.domain())
    @

  ###
  # reset - resets the x,y axes back to the original domain
  ###
  reset: () ->
    @remove()
    @init()
    @

  ###
  # zoom - zooms the x,y axes based on the zoomArea object
  #
  # @param {object} zoomArea, an object containing a bounding box of x,y coordinates
  ###
  zoom: (zoomArea) ->
    if zoomArea.x1 > zoomArea.x2
      @xScale.domain([zoomArea.x2, zoomArea.x1])
    else
      @xScale.domain([zoomArea.x1, zoomArea.x2])

    if @axesOpts.x.type == 'datetime'
      @xAxis.tickFormat(d3.time.format(@formatDate()))

    if zoomArea.y1 > zoomArea.y2
      @yScale.domain([zoomArea.y2, zoomArea.y1])
    else
      @yScale.domain([zoomArea.y1, zoomArea.y2])

    trans = @plot.container.transition().duration(750)
    @xGroup.transition(trans).call(@xAxis)
    @xGroup.selectAll('.tick.major').selectAll('text')
      .style('text-anchor', 'end')
      .attr('dx', '-.8em')
      .attr('dy', '.15em')
      .attr('transform', 'rotate(-65)')
    @yGroup.transition(trans).call(@yAxis)

    if @grid
      @grid.remove()
      @grid = new Grid(@, @plot, @options)
    # return
    @

  ###
  # remove - removes the x,y axis groups from the plot
  ###
  remove: () ->
    @xGroup.remove()
    @yGroup.remove()
    if @grid
      @grid.remove()

  ###
  # formatDate - a method that formats the axis date label
  ###
  formatDate: () ->
    xDomain = @xScale.domain()
    duration = moment.duration(moment(xDomain[1]).diff(xDomain[0])).asDays()
    if duration <= 4
      return '%b %d - %H:%M'
    return '%b %d, %Y'


module.exports = Axes
