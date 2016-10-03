class Tooltip
  ###
  # Tooltip
  #
  # @param {object} plot, the plot append the tooltip
  # @param {function} tooltipTemplate, the compiled template to execute for the tooltip
  #
  # @return {object} this
  ###
  constructor: (plot, options) ->
    @template = options.tooltipTemplate || _.template("<p>x: <%= obj.x %> y: <%= obj.y %></p>")
    # we render the template without data to get the estimated width of the element
    @element = d3.select('body').append('div')
      .attr('class', 'scatterPlot-tooltip')
      .style('opacity', 0)
      .html(@template({meta:{}}))

    #return
    @

  mouseover: (d, x, y) ->
    box = @element.node().getBoundingClientRect()
    # do not render the tooltip past the right margin
    if (x + box.width) >= (window.innerWidth - 20)
      @element.html(@template(d))
        .style('left', (x - Math.floor(box.width)) + 'px')
        .style('top', (y) + 'px')
    else
      @element.html(@template(d))
        .style('left', (x) + 'px')
        .style('top', (y) + 'px')
    @element.transition().duration(200).style('opacity', 0.9)
    #return
    @

  mouseout: () ->
    @element.transition().duration(500).style('opacity', 0)
    # return
    @


module.exports = Tooltip
