class Tooltip
  ###
  # Tooltip
  #
  # @param {object} plot, the plot append the tooltip
  # @param {object} options, the options for the plot
  # @param {object} options.tooltip, the options for the tooltip
  # @param {number} options.opacity, the opacity of the tooltip
  # @param {object} options.template, an underscore compiled template
  #
  # @return {object} this
  ###
  constructor: (plot, options) ->
    @tooltipOpts = options.tooltip || { 'opacity': 0.9, 'template': _.template("<p>x: <%= obj.x %> y: <%= obj.y %></p>")}
    @template = @tooltipOpts.template
    @opacity = @tooltipOpts.opacity
    # we render the template without data to get the estimated width of the element
    @element = d3.select('body').append('div')
      .attr('class', 'scatterPlot-tooltip')
      .style('opacity', 0)
      .html(@template({meta:{}}))
    #return
    @

  ###
  # mouseover - unbound method for mouseover event
  #
  # @param {object} d, the marker with meta data
  # @param {number} x, the x coordinate
  # @param {number} y, the y coordinate
  #
  # @return {object} this
  ###
  mouseover: (d, x, y) ->
    box = @element.node().getBoundingClientRect()
    # do not render the tooltip past the right margin
    if (x + box.width) >= (window.innerWidth - 20)
      @element.html(@template(d))
        .style('left', ((x - 10)  - Math.floor(box.width)) + 'px')
        .style('top', (y) + 'px')
    else
      @element.html(@template(d))
        .style('left', (x + 10) + 'px')
        .style('top', (y) + 'px')
    @element.transition().duration(200).style('opacity', @opacity)
    #return
    @

  ###
  # mouseout - unbound method for mouseout event
  #
  # @return {object} this
  ###
  mouseout: () ->
    @element.transition().duration(500).style('opacity', 0)
    # return
    @

  ###
  # remove - removes the element from the DOM
  ###
  remove: () ->
    @element.remove()


module.exports = Tooltip
