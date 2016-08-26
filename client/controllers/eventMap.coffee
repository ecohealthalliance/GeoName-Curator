MapHelpers = require '/imports/ui/mapMarkers.coffee'

L.Icon.Default.imagePath = "/packages/fuatsengul_leaflet/images"

Template.mapLegend.onRendered ->
  # Prevent clicks from going through the widget
  L.DomEvent.disableClickPropagation @find('.map-legend-tab')
  L.DomEvent.disableClickPropagation @find('.map-legend-drawer')

Template.mapLegend.helpers
  getEvents: ->
    return Template.instance().data.events

Template.markerPopup.helpers
  getEvents: ->
    return Template.instance().data.events

Template.eventMap.onCreated ->
  @query = new ReactiveVar({})
  @pageNum = new ReactiveVar(0)
  @eventsPerPage = 5

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
  legend = L.control({position: 'bottomleft'})
  legend.onAdd = (map) ->
    L.DomUtil.create('div', 'map-legend-container')
  legend.addTo(map)

  reactiveTemplateId = null
  @autorun ->
    map.removeLayer(markers)
    markers = new L.FeatureGroup()
    query = instance.query.get()
    currentPage = instance.pageNum.get()
    Blaze.remove reactiveTemplateId if reactiveTemplateId

    if _.isObject query
      allEvents = instance.data.events.find(query, {sort: {creationDate: -1}}).fetch()
      totalEventCount = allEvents.length
      startingPosition = currentPage * instance.eventsPerPage
    else
      map.removeLayer(markers)
      return
    mapLocations = {}
    templateEvents = []
    eventIndex = startingPosition

    if totalEventCount
      filteredEvents = []
      colorScale = chroma.scale(MapHelpers.getDefaultGradientColors()).colors(instance.eventsPerPage)
      
      #Remove events that have no locations to plot on the map
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
          templateEvents.push({name: event.eventName, date: event.creationDate.toDateString(), rgbColor: rgbColor})

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

      disablePrev = if eventIndex < totalEventCount then false else true
      disableNext = if currentPage is 0 then true else false
      reactiveTemplateId = Blaze.renderWithData(Template.mapLegend, {
        disablePrev: disablePrev
        disableNext: disableNext
        events: templateEvents
      }, legend.getContainer())

    map.addLayer(markers)

Template.eventMap.helpers
  getQuery: ->
    Template.instance().query

Template.eventMap.events
  "click .legend-next": (event, template) ->
    template.pageNum.set(template.pageNum.get() - 1)
  "click .legend-prev": (event, template) ->
    template.pageNum.set(template.pageNum.get() + 1)
  "click .map-legend-tab": (event, template) ->
    $target = template.$(event.target)
    if $target.hasClass("map-legend-tab")
      $target = $target.find(".fa")
    if $target.hasClass("fa-angle-down")
      $target.removeClass("fa-angle-down").addClass("fa-angle-up")
      template.$(".map-legend-drawer").addClass("closed")
    else
      $target.removeClass("fa-angle-up").addClass("fa-angle-down")
      template.$(".map-legend-drawer").removeClass("closed")
