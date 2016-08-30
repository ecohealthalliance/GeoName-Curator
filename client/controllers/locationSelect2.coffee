formatLocation = require '/imports/formatLocation.coffee'

incidentsToLocations = (incidents) ->
  locations = {}
  # Loop 1: Incident Reports
  for incident in incidents
    if incident?.locations
      # Loop 2: Locations within each incident record
      for loc in incident.locations
        if !locations[loc.geonameId]
          locations[loc.geonameId] = loc
  # Return
  _.values(locations)

Template.locationSelect2.onCreated ->
  # Display locations relevant to this event
  @suggestLocations = (term, callback) ->
    locations = incidentsToLocations Incidents.find().fetch()
    data = []
    for loc in locations
      data.push { id: loc.geonameId, text: formatLocation(loc), item: loc }
    callback results: data
  # Retrieve locations from a server
  @ajax = (term, callback) ->
    $.ajax({
      url: "https://geoname-lookup.eha.io/api/lookup"
      data: {
        q: term
        maxRows: 10
      }
    })
    .done (data) ->
      callback results: data.hits.map (hit) ->
        { id, latitude, longitude } = hit._source
        # Ensure numeric lat/lng
        latitude = parseFloat(latitude)
        longitude = parseFloat(longitude)
        # Return
        {
          id: id
          text: formatLocation(hit._source)
          item: hit._source
        }

Template.locationSelect2.onRendered ->
  $input = @$("#" + @data.selectId)
  $input.select2
    multiple: @data.multiple
    placeholder: "Search for a location..."
    minimumInputLength: 1
    ajax:
      url: "https://geoname-lookup.eha.io/api/lookup"
      data: (params) ->
        return {
          q: params.term
          maxRows: 10
        }
      delay: 600
      processResults: (data) ->
        return {
          results: data.hits.map (hit)->
            {
              id
              name
              name
              countryName
              admin1Name
              latitude
              longitude
            } = hit._source
            # Ensure numeric lat/lng
            latitude = parseFloat(latitude)
            longitude = parseFloat(longitude)
            return {
              id: id
              text: formatLocation(hit._source)
              item: hit._source
            }
        }

  $.fn.select2.amd.define('select2/data/queryAdapter',
    [ 'select2/data/array', 'select2/utils' ],
    (ArrayAdapter, Utils) =>
      CustomDataAdapter = ($element, options) ->
        CustomDataAdapter.__super__.constructor.call(@, $element, options)
      Utils.Extend(CustomDataAdapter, ArrayAdapter)
      CustomDataAdapter.prototype.query = (params, callback) =>
        term = params.term?.trim()
        if term # Query the remote server for any matching locations
          @ajax(term, callback)
        else # Show recently used locations for the current event
          @suggestLocations(term, callback)
      CustomDataAdapter
  )
  queryDataAdapter = $.fn.select2.amd.require('select2/data/queryAdapter')
  @$("#" + @data.selectId).select2
    multiple: @data.multiple
    placeholder: "Search for a location..."
    minimumInputLength: 0
    dataAdapter: queryDataAdapter
