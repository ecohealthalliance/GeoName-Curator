L.Icon.Default.imagePath = "/packages/fuatsengul_leaflet/images"

Template.eventMap.created = ->
  @query = new ReactiveVar({})

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

  @autorun ->
    map.removeLayer(markers)
    markers = new L.FeatureGroup()
    query = instance.query.get()

    if _.isObject query
      filteredEvents = instance.data.events.find(query).fetch()
    else
      map.removeLayer(markers)
      return
    mapLocations = {}

    for event in filteredEvents
      eventLocations = instance.data.locations.find({userEventId: event._id}).fetch()
      for location in eventLocations
        latLng = location.latitude.toString() + "," + location.longitude.toString()
        if not mapLocations[latLng]
          mapLocations[latLng] = {name: location.displayName, events: []}
        mapLocations[latLng].events.push({id: event._id, name: event.eventName, mapColorRGB: event.mapColorRGB})

    for coordinates, loc of mapLocations
      popupHtml = "<h5>" + loc.name + "</h5>"

      for event in loc.events
        popupHtml += '<p><svg height="8" width="8"><circle fill="rgb(' + event.mapColorRGB + ')" stroke="black" stroke-width="1" r="4" cx="4" cy="4"></circle></svg><a href="user-event/' + event.id + '">' + event.name + '</a></p>'

      marker = L.marker(coordinates.split(","), {
        icon: L.divIcon({
          className: 'map-marker-container'
          iconSize:null
          html: Meteor.mapHelpers.getMarkerHtml(loc.events)
        })
      }).bindPopup(popupHtml)
      markers.addLayer(marker)

    map.addLayer(markers)

Template.eventMap.helpers
  getQuery: ->
    Template.instance().query
