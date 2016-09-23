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
  # @returns {object} this, returns itself for chaining
  #
  # example usage:
  #  within your template add `<div id="scatterPlot" class="scatterPlot-container">` element
  #  within your template helper, construct a new ScatterPlot instance `plot = new ScatterPlot(options)`
  ###
  constructor: (options) ->
    @options = options
    id = "\##{@options.containerID}"
    @root = d3.select(id).append("svg").attr("preserveAspectRatio", "xMinYMin meet").attr("viewBox", "0 0 300 300").classed(options.svgContentClass, true);
    @

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
    @root.append('rect').attr('x', x).attr('y', y).attr('width', w).attr('height', h).style('fill', f).style('opacity', o)
    @

module.exports = ScatterPlot
