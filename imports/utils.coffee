###
# cleanUrl - takes an existing url and removes the last match of the applied
#   regular expressions.
#
# @param {string} existingUrl, the url to be cleaned
# @param {array} [regexps], (optional) an array of compiled regular expressions
# @returns {string} cleanedUrl, an url that has been cleaned
###
export cleanUrl = (existingUrl, regexps) ->
  regexps = regexps || [new RegExp('^(https?:\/\/)', 'i'), new RegExp('^(www\.)', 'i')]
  cleanedUrl = existingUrl
  regexps.forEach (r) ->
    found = false
    match = cleanedUrl.match(r)
    if match && match.length > 0
      cleanedUrl = cleanedUrl.replace(match[match.length-1], '')
  return cleanedUrl

###
# formatUrl - takes an cleaned url and adds 'http' so that a browser can open
#
# @param {string} existingUrl, the url to be formatted
# @returns {string} formattedUrl, an url that has 'http' added
###
export formatUrl = (existingUrl) ->
  regexp = new RegExp('^(https?:\/\/)', 'i')
  if regexp.test existingUrl
    return existingUrl
  else
    return 'http://' + existingUrl

checkIncidentTypeValue = (form, input) ->
  if not form[input].value.trim()
    messageText = 'count'
    if input is 'specify'
      messageText = 'incident type'
    toastr.error("Please enter a valid #{messageText}.")
    false
  else
    true

export incidentReportFormToIncident = (form) ->
  $form = $(form)
  $articleSelect = $(form.articleSource)
  if $form.find('#singleDate').hasClass('active')
    rangeType = 'day'
    $pickerContainer = $form.find('#singleDatePicker')
  else
    rangeType = 'precise'
    $pickerContainer = $form.find('#rangePicker')

  picker = $pickerContainer.data('daterangepicker')

  incidentType = $form.find('input[name="incidentType"]:checked').val()
  incidentStatus = $form.find('input[name="incidentStatus"]:checked').val()

  incident =
    species: form.species.value
    travelRelated: form.travelRelated.checked
    approximate: form.approximate.checked
    locations: []
    status: incidentStatus
    dateRange:
      type: rangeType
      start: moment.utc(picker.startDate.format("YYYY-MM-DD")).toDate()
      end: moment.utc(picker.endDate.format("YYYY-MM-DD")).toDate()
      cumulative: form.cumulative.checked

  switch incidentType || ''
    when 'cases'
      incident.cases = parseInt(form.count.value, 10)
    when 'deaths'
      incident.deaths = parseInt(form.count.value, 10)
    when 'other'
      incident.specify = form.specify.value.trim()
    else
      toastr.error("Unknown incident type [#{incidentType}]")
      return

  for child in $articleSelect.select2('data')
    if child.selected
      incident.url = [child.text.trim()]

  $loc = $(form).find('#incident-location-select2')
  for option in $loc.select2('data')
    item = option.item
    if typeof item.alternateNames is 'string'
      delete item.alternateNames
    incident.locations.push(item)
  return incident

export UTCOffsets =
  ADT:  '-0300'
  AKDT: '-0800'
  AKST: '-0900'
  AST:  '-0400'
  CDT:  '-0500'
  CST:  '-0600'
  EDT:  '-0400'
  EGST: '+0000'
  EGT:  '-0100'
  EST:  '-0500'
  HADT: '-0900'
  HAST: '-1000'
  MDT:  '-0600'
  MST:  '-0700'
  NDT:  '-0230'
  NST:  '-0330'
  PDT:  '-0700'
  PMDT: '-0200'
  PMST: '-0300'
  PST:  '-0800'
  WGST: '-0200'
  WGT: '-0300'

export regexEscape = (s)->
  # Based on bobince's regex escape function.
  # source: http://stackoverflow.com/questions/3561493/is-there-a-regexp-escape-function-in-javascript/3561711#3561711
  s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')
