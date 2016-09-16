convertDate = (convertDate, currentOffset, targetOffset) ->
  converted = moment(convertDate)
  currentMinuteOffset = converted.utcOffset()
  if currentOffset isnt "local"
    offset = parseInt(currentOffset)
    currentMinuteOffset = (parseInt(offset / 100) * 60) + (offset % 100)
  targetMinuteOffset = converted.utcOffset()
  if targetOffset isnt "local"
    offset = parseInt(targetOffset)
    targetMinuteOffset = (parseInt(offset / 100) * 60) + (offset % 100)
  # Convert back to GMT
  converted.add(currentMinuteOffset * -1, "minutes")
  # Convert to target offset
  converted.add(targetMinuteOffset, "minutes")
  return converted

module.exports = convertDate
