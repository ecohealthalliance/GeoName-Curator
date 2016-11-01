import d3 from 'd3'
import Node from '/imports/charts/Node.coffee'
import { InvalidNodeError } from '/imports/charts/Errors.coffee'
import _ from 'underscore'


genId = () ->
  length = 9
  prefix = 'group-'
  prefix + Math.random().toString(36).substr(2, length);

class Group
  name: 'Group'
  constructor: (plot, options) ->
    @options = options || {}
    @id = @options.id || genId()
    onEnter = @options.onEnter || Group.onEnter
    @onEnter = _.bind(onEnter, @)
    onUpdate = @options.onUpdate || Group.onUpdate
    @onUpdate = _.bind(onUpdate, @)
    onExit = @options.onExit || Group.onExit
    @onExit = _.bind(onExit, @)
    @nodes_ = {}
    @plot = plot
    @plot.addGroup(@)

  ###
  # size - returns the size of the Group's nodes
  #
  # @return {number} size, the size of the group
  ###
  size: () ->
    Object.values(@nodes_).length

  ###
  # addNode - adds a node to this group
  #
  # @param {object} node, the node to add
  # @throws {InvalidGroupError} error
  # @return {Group} this
  ###
  addNode: (node) ->
    if !node instanceof Node
      throw new InvalidNodeError()
    @nodes_[node.id] = node
    # return
    @

  ###
  # removeNode - removes a node from this group
  #
  # @param {string} id, the id to remove
  # @return {object} this
  ###
  removeNode: (id) ->
    if @nodes_.hasOwnProperty(id)
      delete @nodes_[id]
    #return
    @

  ###
  # getNodes - returns the nodes associated with this group
  #
  # @return {array} nodes, the nodes associated with this group
  ###
  getNodes: () ->
    Object.values(@nodes_)

  ###
  # update - handles updating the marker
  #
  # @return {object} this
  ###
  update: () ->
    if typeof @group == 'undefined'
      return
    filtered = @applyFilters()
    filteredLen = filtered.length
    @group.attr('numNodes', filteredLen)
    nodes = @group.selectAll('.node').data(filtered, (d) -> d.id)
    nodes.enter().append((node) -> node.detached()).call(@onEnter)
    nodes.each((node) -> node.update()).call(@onUpdate)
    nodes.exit().remove().call(@onExit)

  ###
  # detached - builds a detached svg group and returns the node
  #
  # @return {object} node, the SVG node to append to the parent during .call()
  ###
  detached: () ->
    @remove()
    @group = d3.select(document.createElementNS(d3.namespaces.svg, 'g')).attr('id', @id).attr('class', 'group').remove()
    @update()
    #returns
    @group.node()

  ###
  # applyFilters - apply any filters from the plot
  #
  # @param {object} filters, an array of filters to apply
  # @returns {array} filtered, the filtered data
  ###
  applyFilters: (filters) ->
    filters = filters || @plot.filters
    filtered = []
    if @nodes_
      filtered = @getNodes().filter (d) ->
        valid = true
        keys = Object.keys(filters)
        i = 0
        keysLen = keys.length
        while i < keysLen
          key = keys[i++]
          f = filters[key](d)
          if typeof f == 'undefined'
            valid = false
            break
        if valid
          return d
    return filtered

  ###
  # remove - removes the group from the DOM
  ###
  remove: () ->
    # remove layer from the plot
    if @group
      @group.remove()
    #return
    @

  ###
  # destroy - destroys the group and any associated elements
  ###
  destroy: () ->
    @remove()
    @plot.removeLayer(@id)
    @nodes = null
    @plot = null
    @group = null


###
# onEnter - the default event handler for a group. This may be overridden or
#   a new event handler passed into the constructor as `options.onEnter`
#
# @param {object} selections - the d3 selection object containing the children for this group
###
Group.onEnter = () ->
  return

###
# onUpdate - the default event handler for a group. This may be overridden or
#   a new event handler passed into the constructor as `options.onUpdate`
#
# @param {object} selections - the d3 selection object for this group
###
Group.onUpdate = (selections) ->
  return

###
# onExit - the default event handler for a group. This may be overridden or
#   a new event handler passed into the constructor as `options.onExit`
#
# @param {object} selections - the d3 selection object for this group
###
Group.onExit = (selections) ->
  return


module.exports = Group
