MapHelpers = require '/imports/ui/mapMarkers.coffee'

L.Icon.Default.imagePath = "/packages/fuatsengul_leaflet/images"

Template.mapLegend.helpers
  getEvents: ->
    return Template.instance().data.events

Template.markerPopup.helpers
  getEvents: ->
    return Template.instance().data.events

Template.eventMap.created = ->
  @query = new ReactiveVar({})
  @pageNum = new ReactiveVar(0)
  @eventsPerPage = 5

Template.eventMap.rendered = ->

  bounds = L.latLngBounds(L.latLng(-85, -180), L.latLng(85, 180))

  map = L.map('event-map',
    maxBounds: bounds
    ).setView([10, -0], 3)
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
    @_div = L.DomUtil.create('div', 'map-legend-container')
    @update()
    return @_div

  legend.update = (html) ->
    @_div.innerHTML = html

  legend.addTo(map)

  @autorun ->
    map.removeLayer(markers)
    markers = new L.FeatureGroup()
    query = instance.query.get()
    legendHtml = ""
    currentPage = instance.pageNum.get()

    if _.isObject query
      allEvents = instance.data.events.find(query, {sort: {creationDate: -1}}).fetch()
      startingPosition = currentPage * instance.eventsPerPage
      totalEventCount = allEvents.length

      filteredEvents = allEvents.slice(startingPosition, startingPosition + instance.eventsPerPage)
    else
      map.removeLayer(markers)
      return
    mapLocations = {}

    if filteredEvents.length
      templateEvents = []
      colorCount = if filteredEvents.length is 1 then 2 else filteredEvents.length
      colorScale = chroma.scale(MapHelpers.getDefaultGradientColors()).colors(colorCount)

      for i in [0..filteredEvents.length - 1]
        event = filteredEvents[i]
        eventLocations = instance.data.locations.find({userEventId: event._id}).fetch()
        rgbColor = chroma(colorScale[i]).rgb()
        templateEvents.push({name: event.eventName, date: event.creationDate.toDateString(), rgbColor: rgbColor})

        for location in eventLocations
          latLng = location.latitude.toString() + "," + location.longitude.toString()
          if not mapLocations[latLng]
            mapLocations[latLng] = {name: location.displayName, events: []}
          mapLocations[latLng].events.push({id: event._id, name: event.eventName, mapColorRGB: rgbColor})

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

      disablePrev = if totalEventCount - ((currentPage * instance.eventsPerPage) + instance.eventsPerPage) <= 0 then true else false
      disableNext = if currentPage is 0 then true else false
      legendHtml = Blaze.toHTMLWithData(Template.mapLegend, {disablePrev: disablePrev, disableNext: disableNext, events: templateEvents})

    map.addLayer(markers)
    legend.update(legendHtml)

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