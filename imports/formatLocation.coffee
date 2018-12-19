formatLocation = ({name, admin2Name, admin1Name, countryName, featureCode}) ->
  return _.chain([name, admin2Name, admin1Name, countryName])
    .compact()
    .uniq()
    .value()
    .join(", ") + " [#{featureCode}]"

module.exports = formatLocation
