dateStringToDate = (dateString, delim) ->
  dateSplit = dateString.split(delim)
  # months are 0 indexed, so subtract 1 when creating the date
  return new Date(dateSplit[2], dateSplit[0] - 1, dateSplit[1])

dateToAbbrvDateString = (date) ->
  return (date.getMonth() + 1) + "/" + date.getDate() + "/" + date.getFullYear()

module.exports = {
  dateStringToDate: dateStringToDate
  dateToAbbrvDateString: dateToAbbrvDateString
}