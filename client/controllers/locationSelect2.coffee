formatLocation = require '/imports/formatLocation.coffee'

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
  #override the inline width of the select2 container and its text input field
  $input.next(".select2-container").css("width", "100%").find("input").css("width", "100%")
