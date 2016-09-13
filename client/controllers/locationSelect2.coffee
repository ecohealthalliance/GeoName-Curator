formatLocation = require '/imports/formatLocation.coffee'

incidentsToLocations = (incidents) ->
  locations = {}
  # Loop 1: Incident Reports
  for incident in incidents
    if incident?.locations
      # Loop 2: Locations within each incident record
      for loc in incident.locations
        if !locations[loc.id]
          locations[loc.id] = loc
  # Return
  _.values(locations)

Template.locationSelect2.onCreated ->
  # Display locations relevant to this event
  @suggestLocations = (term, callback) ->
    locations = incidentsToLocations Incidents.find().fetch()
    data = []
    for loc in locations
      data.push { id: loc.id, text: formatLocation(loc), item: loc }
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
        hit._source.latitude = parseFloat(latitude)
        hit._source.longitude = parseFloat(longitude)
        return {
          id: id
          text: formatLocation(hit._source)
          item: hit._source
        }

Template.locationSelect2.onRendered ->
  initialValues = []
  if @data.selected
    initialValues = @data.selected.map (loc)->
      id: loc.id
      text: formatLocation(loc)
      item: loc
  $input = @$("select")
  $.fn.select2.amd.define('select2/data/queryAdapter',
    [ 'select2/data/array', 'select2/utils' ],
    (ArrayAdapter, Utils) =>
      CustomDataAdapter = ($element, options) ->
        CustomDataAdapter.__super__.constructor.call(@, $element, options)
      Utils.Extend(CustomDataAdapter, ArrayAdapter)
      CustomDataAdapter.prototype.query = _.debounce (params, callback) =>
        term = params.term?.trim()
        if term # Query the remote server for any matching locations
          @ajax(term, callback)
        else # Show recently used locations for the current event
          @suggestLocations(term, callback)
      , 600
      CustomDataAdapter
  )
  queryDataAdapter = $.fn.select2.amd.require('select2/data/queryAdapter')
  $input.select2
    data: initialValues
    multiple: @data.multiple
    placeholder: "Search for a location..."
    minimumInputLength: 0
    dataAdapter: queryDataAdapter
  if initialValues.length > 0
    $input.val(initialValues.map((x)->x.id)).trigger("change")
