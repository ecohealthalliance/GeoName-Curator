formatLocation = ({name, admin2Name, admin1Name, countryName}) ->
  return _.chain([name, admin2Name, admin1Name, countryName])
    .compact()
    .uniq()
    .value()
    .join(", ")

module.exports = formatLocation

UI.registerHelper 'formatLocation', (location)->
  return formatLocation(
    name: location.displayName
    admin1Name: location.subdivision
    countryName: location.countryName
  )
