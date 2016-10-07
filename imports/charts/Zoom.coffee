class Zoom
  ###
  # Zoom
  ###
  constructor: (plot, options) ->
    @plot = plot
    @options = options

    @bandPos = [-1, -1];
    @zoomArea =
      x1: @options.axes.x.minMax[0],
      y1: @options.axes.y.minMax[0],
      x2: @options.axes.x.minMax[1],
      y2: @options.axes.y.minMax[1]
    @drag = d3.behavior.drag();
    @zoomGroup = plot.container.append('g').attr('class', 'scatterPlot-zoom')
    @zoomBand = @zoomGroup.append('rect')
      .attr('width', 0)
      .attr('height', 0)
      .attr('x', 0)
      .attr('y', 0)
      .attr('class', 'zoomBand')
    @zoomOverlay = @zoomGroup.append('rect')
      .attr('width', plot.getWidth())
      .attr('height', plot.getHeight())
      .attr('transform', "translate(#{plot.margins.left}, 0)")
      .attr('class', 'zoomOverlay')
      .call(@drag);
    @resetZoomGroup = plot.container.append('g').attr('class', 'scatterPlot-resetZoom')
    @resetZoomBtn = @resetZoomGroup.append('rect')
      .attr('class', 'resetZoomBtn')
      .attr('width', 75)
      .attr('height', 20)
      .attr('x', plot.getWidth() + plot.margins.right)
      .attr('y', plot.getHeight() + (plot.margins.bottom + 10))
      .on('click', _.bind(@resetZoom,@))
    @resetZoomGroup.append('text')
      .attr('class', 'resetZoomText')
      .attr('width', 75)
      .attr('height', 20)
      .attr('x', plot.getWidth() + (plot.margins.right + 2))
      .attr('y', plot.getHeight() + (plot.margins.bottom + 24))
      .text('Reset Zoom');

    self = @
    @drag.on 'drag.plot', () ->
      # Note: @ (this) is not the Zoom class but the DOM event
      pos = d3.mouse(@)
      self.dragStart = pos[0]
      _.bind(self.ondrag, self)(pos)

    @drag.on 'dragend.plot', () ->
      # Note: @ (this) is not the Zoom class but the DOM event
      pos = d3.mouse(@)
      _.bind(self.ondragend, self)(pos)

  ###
  # ondrag
  ###
  ondrag: (pos) ->
    if pos[0] < @bandPos[0]
      @zoomBand.attr('transform', "translate(#{(pos[0] + @plot.margins.left)}, #{@bandPos[1]})")
    if pos[1] < @bandPos[1]
      @zoomBand.attr('transform', "translate(#{(pos[0] + @plot.margins.left)}, #{pos[1]})")
    if pos[1] < @bandPos[1] and pos[0] > @bandPos[0]
      @zoomBand.attr('transform', "translate(#{(@bandPos[0] + @plot.margins.left)}, #{pos[1]})")
    if @bandPos[0] == -1
      @bandPos = pos;
      @zoomBand.attr('transform', "translate(#{(@bandPos[0] + @plot.margins.left)}, #{@bandPos[1]})")
    @zoomBand.transition().duration(1)
      .attr('width', Math.abs(@bandPos[0] - pos[0]))
      .attr('height', Math.abs(@bandPos[1] - pos[1]))

  ###
  # ondragend
  ###
  ondragend: (pos) ->
    x1 = @plot.axes.xScale.invert(@bandPos[0])
    x2 = @plot.axes.xScale.invert(pos[0])
    if x1 < x2
      @zoomArea.x1 = x1
      @zoomArea.x2 = x2
    else
      @zoomArea.x1 = x2
      @zoomArea.x2 = x1

    y1 = @plot.axes.yScale.invert(pos[1]);
    y2 = @plot.axes.yScale.invert(@bandPos[1])
    if y1 < y2
      @zoomArea.y1 = y1
      @zoomArea.y2 = y2
    else
      @zoomArea.y1 = y2
      @zoomArea.y2 = y1

    @bandPos = [-1, -1];
    @zoomBand.transition()
      .attr('width', 0)
      .attr('height', 0)
      .attr('x', @bandPos[0])
      .attr('y', @bandPos[1])
    @zoom()


  ###
  # zoom
  ###
  zoom: () ->
    @plot.axes.zoom(@zoomArea)

  ###
  # resetZoom -
  ###
  resetZoom: () ->
    @plot.axes.reset()

  ###
  # remove
  ###
  remove: () ->
    @zoomGroup.remove()
    @resetZoomGroup.remove()
    @drag.on('drag.plot', null)
    @drag.on('dragend.plot', null)


module.exports = Zoom
