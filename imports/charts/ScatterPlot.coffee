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
    @margins = options.margins || {left: 40, right: 20, top: 20, bottom: 40}
    @width = options.width || document.getElementById(options.containerID).offsetWidth - (@margins.left + @margins.right);
    @height = options.height || ScatterPlot.aspectRatio() * @width

    # the root elment of the plot
    @root = d3.select("\##{options.containerID}").append('svg')
      .attr('width', @width + @margins.left + @margins.right)
      .attr('height', @height + @margins.top + @margins.bottom)
      .append('g')
      .attr('transform', "translate(#{@margins.left}, #{@margins.top})")

    # an svg group of the markers
    @markers = @root.append('g')
      .attr('class', 'scatterPlot-rect-markers')
      .attr('transform', "translate(#{@margins.left}, 0)")

    # the axes of the plot
    @axes = new Axes(@, options)

    # return
    @

  ###
  # getWidth
  #
  # @return {number} width (excluding margins) for the root svg
  ###
  getWidth: () ->
    @width - (@margins.left + @margins.right)

  ###
  # getHeigth
  #
  # @return {number} width (excluding margins) for the root svg
  ###
  getHeight: () ->
    @height - (@margins.top + @margins.bottom)

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
  addRectMarker: (x, y, w, h, f, o) ->
    @markers.append('rect')
      .attr('x', @axes.xScale(x))
      .attr('y', @axes.yScale(y))
      .attr('width', @axes.xScale(w) - @axes.xScale(x))
      .attr('height', @getHeight() - @axes.yScale(1))
      .style('fill', f)
      .style('opacity', o)
    @


module.exports = ScatterPlot

###
# maxNumeric - determine the maximum value with padding. Padding is determined
# by the number of digits ^ 10 / 10
#
# @return {number} max
###
ScatterPlot.maxNumeric = (data) ->
  m = _.max(data)
  l = String(m).split('').length
  p = (Math.pow(10, l)) / 10
  m + p

###
# maxDatetime - determine the maximum value with padding
#
# @param {array} data, an array of timestamps in milliseconds
# @param {string} unit, the padding unit {day, month, year}
# @param {numeric} amount, the amount of padding
# @return {number} max, maximum datetime value
###
ScatterPlot.maxDatetime = (data, unit, amount) ->
  m = _.max(data)
  moment(m).add(amount, unit).valueOf()

###
# minDatetime - determine the minimum value with padding
#
# @param {array} data, an array of timestamps in milliseconds
# @param {string} unit, the padding unit {day, month, year}
# @param {numeric} amount, the amount of padding
# @return {number} min, minimum datetime value
###
ScatterPlot.minDatetime = (data, unit, amount) ->
  m = _.min(data)
  moment(m).subtract(amount, unit).valueOf()

# find the view port aspect ratio
#
# @return {number} aspectRatio
ScatterPlot.aspectRatio = () ->
  $(window).height() / $(window).width()
