import d3 from 'd3'

genId = () ->
  length = 9
  prefix = 'node-'
  prefix + Math.random().toString(36).substr(2, length);

class Node
  name: 'Node'
  ###
  # Node - base class
  #
  # @param {object} options, the options used to construct the SegmentMarker
  # @param {object} options.meta, the optional meta data associated with the node (e.g. used in the Tooltip)
  # @return {object} this
  ###
  constructor: (options) ->
    @id = options.id || genId()
    @meta = options.meta || {}

    #return
    @

module.exports = Node
