MapHelpers = require '/imports/ui/mapMarkers.coffee'

L.Icon.Default.imagePath = "/packages/fuatsengul_leaflet/images"

Template.eventMap.onCreated ->
  @query = new ReactiveVar({})
  @pageNum = new ReactiveVar(0)
  @eventsPerPage = 10
  @templateEvents = new ReactiveVar null
  @disablePrev = new ReactiveVar false
  @disableNext = new ReactiveVar true
  @selectedEvents = new Meteor.Collection null

Template.eventMap.onRendered ->
  bounds = L.latLngBounds(L.latLng(-85, -180), L.latLng(85, 180))

  map = L.map('event-map', maxBounds: bounds).setView([10, -0], 3)
  L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
    attribution: """Map tiles by <a href="http://cartodb.com/attributions#basemaps">CartoDB</a>, under <a href="https://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>. Data by <a href="http://www.openstreetmap.org/">OpenStreetMap</a>, under ODbL.
    <br>
    CRS:
    <a href="http://wiki.openstreetmap.org/wiki/EPSG:3857" >
    EPSG:3857
    </a>,
    Projection: Spherical Mercator""",
    subdomains: 'abcd',
    type: 'osm'
    noWrap: true
    minZoom: 2
    maxZoom: 18
  }).addTo(map)

  @filteredMapLocations = {}
  @mapMarkers = new L.FeatureGroup()
  instance = @

  @autorun ->
    query = instance.query.get()
    currentPage = instance.pageNum.get()
    eventsPerPage = instance.eventsPerPage

    if _.isObject query
      allEvents = instance.data.events.find(query, {sort: {creationDate: -1}}).fetch()
      startingPosition = currentPage * eventsPerPage
      totalEventCount = allEvents.length
    else
      map.removeLayer instance.mapMarkers
      return

    filteredMapLocations = instance.filteredMapLocations = {}
    templateEvents = []
    eventIndex = startingPosition

    if totalEventCount
      filteredEvents = []
      colorScale = chroma.scale(MapHelpers.getDefaultGradientColors()).colors(eventsPerPage)

      # Remove events that have no locations to plot on the map
      filteredEvents = []
      for event in allEvents
        incidentLocations = instance.data.incidents.find({userEventId: event._id, locations: {$ne: null}}, {fields: {locations: 1}}).fetch()
        if incidentLocations.length
          event.incidents = incidentLocations
          filteredEvents.push event

      if filteredEvents.length
        while templateEvents.length < eventsPerPage and eventIndex < filteredEvents.length
          event = filteredEvents[eventIndex]
          rgbColor = chroma(colorScale[templateEvents.length]).rgb()
          templateEvents.push
            _id: event._id
            name: event.eventName
            date: event.creationDate.toDateString()
            rgbColor: rgbColor
            incidents: event.incidents
          MapHelpers.addEventToMarkers filteredMapLocations, event, rgbColor
          eventIndex += 1

    instance.templateEvents.set templateEvents
    instance.disablePrev.set if eventIndex < totalEventCount then false else true
    instance.disableNext.set if currentPage is 0 then true else false
    if instance.allMapMarkers
      map.removeLayer instance.allMapMarkers
    MapHelpers.addMarkersToMap map, instance, filteredMapLocations

  # Update the map markers to reflect user selection of events
  @autorun ->
    _selectedEvents = instance.selectedEvents.find().fetch()
    if _selectedEvents.length
      selecedMapLocations = {}
      _.each _selectedEvents, (selectedEvent) ->
        MapHelpers.addEventToMarkers selecedMapLocations, selectedEvent, selectedEvent.rgbColor
      MapHelpers.addMarkersToMap map, instance, selecedMapLocations
    else
      MapHelpers.addMarkersToMap map, instance, instance.filteredMapLocations


Template.eventMap.helpers
  getQuery: ->
    Template.instance().query

  templateEvents: ->
    Template.instance().templateEvents

  disablePrev: ->
    Template.instance().disablePrev

  disableNext: ->
    Template.instance().disableNext

  query: ->
    Template.instance().query

  selectedEvents: ->
    Template.instance().selectedEvents

paginate = (template, direction) ->
  template.pageNum.set template.pageNum.get() + direction
  template.selectedEvents.remove {}

Template.eventMap.events
  "click .event-list-next:not('.disabled')": (event, template) ->
    paginate template, -1

  "click .event-list-prev:not('.disabled')": (event, template) ->
    paginate template, 1

Template.markerPopup.helpers
  getEvents: ->
    Template.instance().data.events
