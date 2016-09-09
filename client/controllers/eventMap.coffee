MapHelpers = require '/imports/ui/mapMarkers.coffee'

L.Icon.Default.imagePath = "/packages/fuatsengul_leaflet/images"

Template.eventMap.onCreated ->
  @query = new ReactiveVar({})
  @pageNum = new ReactiveVar(0)
  @eventsPerPage = 5
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

  instance = @
  markers = new L.FeatureGroup()

  reactiveTemplateId = null
  @autorun ->
    map.removeLayer(markers)
    markers = new L.FeatureGroup()
    query = instance.query.get()
    currentPage = instance.pageNum.get()
    Blaze.remove reactiveTemplateId if reactiveTemplateId

    _selectedEvents = instance.selectedEvents.find().fetch()
    if _.isObject query
      allEvents = instance.data.events.find(query, {sort: {creationDate: -1}}).fetch()
      totalEventCount = allEvents.length
      startingPosition = currentPage * instance.eventsPerPage
    else
      map.removeLayer(markers)
    mapLocations = {}
    templateEvents = []
    eventIndex = startingPosition

    _selectedEventsLength = _selectedEvents.length
    if _selectedEventsLength
      selectedEventIds = _.pluck _selectedEvents, 'id'
      totalEventCount = _selectedEventsLength
    else
      selectedEventIds = _.pluck allEvents, '_id'

    console.log selectedEventIds, totalEventCount

    if totalEventCount
      filteredEvents = []
      colorScale = chroma.scale(MapHelpers.getDefaultGradientColors()).colors(instance.eventsPerPage)

      # Remove events that have no locations to plot on the map
      filteredEvents = []
      for event in allEvents
        incidentLocations = instance.data.incidents.find({userEventId: event._id, locations: {$ne: null}}, {fields: {locations: 1}}).fetch()
        if incidentLocations.length
          event.incidents = incidentLocations
          filteredEvents.push(event)

      if filteredEvents.length
        while templateEvents.length < instance.eventsPerPage and eventIndex < filteredEvents.length
          event = filteredEvents[eventIndex]
          rgbColor = chroma(colorScale[templateEvents.length]).rgb()
          templateEvents.push({_id: event._id, name: event.eventName, date: event.creationDate.toDateString(), rgbColor: rgbColor})

          if event._id in selectedEventIds
            uniqueEventLocations = []
            for incident in event.incidents
              for location in incident.locations
                latLng = location.latitude.toString() + "," + location.longitude.toString()
                if uniqueEventLocations.indexOf(latLng) is -1
                  if not mapLocations[latLng]
                    mapLocations[latLng] = {name: location.displayName, events: []}
                  mapLocations[latLng].events.push({id: event._id, name: event.eventName, mapColorRGB: rgbColor})
                  uniqueEventLocations.push(latLng)

          eventIndex += 1

      for coordinates, loc of mapLocations
        popupHtml = Blaze.toHTMLWithData(Template.markerPopup, {location: loc.name, events: loc.events})

        marker = L.marker(coordinates.split(","), {
          icon: L.divIcon({
            className: 'map-marker-container'
            iconSize:null
            html: MapHelpers.getMarkerHtml(loc.events)
          })
        }).bindPopup(popupHtml)
        markers.addLayer(marker)

      instance.templateEvents.set templateEvents
      instance.disablePrev.set if eventIndex < totalEventCount then false else true
      instance.disableNext.set if currentPage is 0 then true else false

    map.addLayer markers
    map.fitBounds markers.getBounds()

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

Template.eventMap.events
  "click .event-list-next": (event, template) ->
    template.pageNum.set template.pageNum.get() - 1

  "click .event-list-prev": (event, template) ->
    template.pageNum.set template.pageNum.get() + 1

Template.markerPopup.helpers
  getEvents: ->
    Template.instance().data.events
