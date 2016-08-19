formatLocation = require '/imports/formatLocation.coffee'

Template.locationSelect2.onRendered ->
  @$("#" + @data.selectId).select2
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
  @$(".select2-container").css("width", "100%")
