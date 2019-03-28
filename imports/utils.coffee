Constants = require '/imports/constants.coffee'
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

export keyboardSelect = (event) ->
  keyCode = event.keyCode
  keyCode in [13, 32]

export removeSuggestedProperties = (instance, props) ->
  suggestedFields = instance.suggestedFields
  suggestedFields.set(_.difference(suggestedFields.get(), props))

export diseaseOptionsFn = (params, callback) ->
  term = params.term?.trim()
  if not term
    return callback(results: [])
  HTTP.get Constants.GRITS_URL + "/api/v1/disease_ontology/lookup", {
    params:
      q: term
  }, (error, response)->
    if error
      return callback(error)
    callback(
      results: response.data.result.map((d)->
        if d.synonym != d.label
          text = d.synonym + " | " + d.label
        else
          text = d.label
        {
          id: d.uri
          text: text
          item: d
        }
      ).concat([
        id: "userSpecifiedDisease:#{term}"
        text: "Other Disease: #{term}"
      ])
    )

# Parse text into an array of sentences separated by
# periods, colons, semi-colons, or double linebreaks.
export parseSents = (text)->
  idx = 0
  sents = []
  sentStart = 0
  while idx < text.length
    char = text[idx]
    if char == '\n'
      [match] = text.slice(idx).match(/^\n+/)
      idx += match.length
      if match.length > 1
        sents[sents.length] = text.slice(sentStart, idx)
        sentStart = idx
    else if /^[\.\;\:]/.test(char)
      idx++
      sents[sents.length] = text.slice(sentStart, idx)
      sentStart = idx
    else
      idx++
  if sentStart < idx
    sents[sents.length] = text.slice(sentStart, idx)
  return sents

# Split annotations with multiple offsets into multiple annotations
# with single offsets
ungroupOffsets = (annotationsWithOffsets)->
  annotationsWithSingleOffsets = []
  annotationsWithOffsets.forEach (annotation)->
    annotation.textOffsets.forEach (textOffset)->
      splitAnnotation = Object.create(annotation)
      splitAnnotation.textOffsets = [textOffset]
      annotationsWithSingleOffsets.push(splitAnnotation)
  annotationsWithSingleOffsets

# A annotation's territory is the sentence containing it,
# and all the following sentences until the next annotation.
# Annotations in the same sentence are grouped.
export getTerritories = (annotationsWithOffsets, sents)->
  annotationsWithOffsets = ungroupOffsets(annotationsWithOffsets)
  annotationsWithOffsets = _.sortBy(annotationsWithOffsets, (annotation)->
    annotation.textOffsets[0][0]
  )
  annotationIdx = 0
  sentStart = 0
  sentEnd = 0
  territories = []
  sents.forEach (sent) ->
    sentStart = sentEnd
    sentEnd = sentEnd + sent.length
    sentAnnotations = []
    while annotation = annotationsWithOffsets[annotationIdx]
      [aStart, aEnd] = annotation.textOffsets[0]
      if aStart > sentEnd
        break
      else
        sentAnnotations.push annotation
        annotationIdx++
    if sentAnnotations.length > 0 or territories.length == 0
      territories.push
        annotations: sentAnnotations
        territoryStart: sentStart
        territoryEnd: sentEnd
    else
      territories[territories.length - 1].territoryEnd = sentEnd
  return territories

export createIncidentReportsFromEnhancements = (enhancements, options)->
  { countAnnotations, acceptByDefault, url, publishDate } = options
  if not publishDate
    publishDate = new Date()
  incidents = []
  features = enhancements.features
  locationAnnotations = features.filter (f) -> f.type == 'location'
  locationAnnotations = ungroupOffsets(locationAnnotations)
  datetimeAnnotations = features.filter (f) -> f.type == 'datetime'
  if not countAnnotations
    countAnnotations = features.filter (f) -> f.type == 'count'
  sents = parseSents(enhancements.source.cleanContent.content)
  locTerritories = getTerritories(locationAnnotations, sents)
  datetimeAnnotations = datetimeAnnotations
    .map (timeAnnotation) =>
      if not (timeAnnotation.timeRange and
        timeAnnotation.timeRange.begin and
        timeAnnotation.timeRange.end
      )
        return
      # moment parses 0 based month indecies
      if timeAnnotation.timeRange.begin.month
        timeAnnotation.timeRange.begin.month--
      if timeAnnotation.timeRange.end.month
        timeAnnotation.timeRange.end.month--
      timeAnnotation.precision = (
        Object.keys(timeAnnotation.timeRange.end).length +
        Object.keys(timeAnnotation.timeRange.end).length
      )
      timeAnnotation.beginMoment = moment.utc(
        timeAnnotation.timeRange.begin
      )
      # Round up the to day end
      timeAnnotation.endMoment = moment.utc(
        timeAnnotation.timeRange.end
      ).endOf('day')
      publishMoment = moment.utc(publishDate)
      if timeAnnotation.beginMoment.isAfter publishMoment, 'day'
        # Omit future dates
        return
      if timeAnnotation.endMoment.isAfter publishMoment, 'day'
        # Truncate ranges that extend into the future
        timeAnnotation.endMoment = publishMoment
      return timeAnnotation
    .filter (x) -> x
  dateTerritories = getTerritories(datetimeAnnotations, sents)
  locationAnnotations.forEach (annotation) =>
    incident =
      locations: [annotation].map(({geoname}) -> geoname)
    annotations =
      location: [
        textOffsets: annotation.textOffsets[0]
      ]
    incident.annotations = annotations
    incident.autogenerated = true
    incident.accepted = true
    incident.url = url
    incidents.push(incident)
  return incidents
