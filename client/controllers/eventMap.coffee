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
    for event in filteredEvents
      if event.locations
        name = event.eventNameVal
        eidID = event.eidID

        for location in event.locations
          latLng = [location.locationLatitude, location.locationLongitude]

          if latLng[0] isnt 'Not Found' and latLng[1] isnt 'Not Found'
            marker = L.marker(latLng, {
              icon: L.divIcon({
                className: 'map-marker-container'
                iconSize:null
                html: '<div class="map-marker"></div>'
              })
            }).bindPopup("""<a href="/event/#{eidID}">#{name}</a>""")
            markers.addLayer(marker)

    map.addLayer(markers)

Template.eventMap.helpers
  getQuery: ->
    Template.instance().query
