annotateContent = (content, annotations, options={})->
  { startingIndex, endingIndex, tag } = options
  if not startingIndex
    startingIndex = 0
  if not endingIndex
    endingIndex = content.length - 1
  if not tag
    tag = "span"
  lastOffset = startingIndex
  html = ""
  if startingIndex isnt 0
    html += "..."
  endpoints = []
  annotations.map (annotation)->
    [start, end] = annotation.textOffsets
    endpoints.push
      offset: start
      otherEndpointOffset: end
      annotation: annotation
      start: true
    endpoints.push
      offset: end
      otherEndpointOffset: start
      annotation: annotation
      start: false
  endpoints = endpoints.sort (a, b)->
    if a.offset < b.offset
      -1
    else if a.offset > b.offset
      1
    else if a.start < b.start
      -1
    else if a.start > b.start
      1
    else if a.otherEndpointOffset < b.otherEndpointOffset
      -1
    else if a.otherEndpointOffset > b.otherEndpointOffset
      1
    else
      0
  activeAnnotations = []
  endpoints.forEach ({offset, annotation, start})->
    html += Handlebars._escape(content.slice(lastOffset, offset))
    if activeAnnotations.length > 0
      html += "</#{annotation.tag or tag}>"
    if start
      activeAnnotations.push(annotation)
    else
      activeAnnotations = _.without(activeAnnotations, annotation)
    if activeAnnotations.length > 0
      types = activeAnnotations.map((a)->
        if a.ignore
          'ignore'
        else
          a.type
      ).filter((a)->a).join(" ")
      attributes = {}
      activeAnnotations.forEach (a)-> _.extend(attributes, a?.attributes or {})
      attributeText = _.map(attributes, (value, key)-> "#{key}='#{value}'").join(" ")
      classAttr = if types then "class='annotation annotation-text #{types}'" else ""
      html += "<#{annotation.tag or tag} #{classAttr} #{attributeText}>"
    lastOffset = offset
  html += Handlebars._escape("#{content.slice(lastOffset, endingIndex)}")
  if endingIndex < content.length - 1
    html += "..."
  html

module.exports =
  annotateContent: annotateContent
  annotateContentWithIncidents: (content, incidents) ->
    incidentAnnotations = incidents.map (incident) ->
      if not incident.annotations?.location[0]
        return
      baseAnnotation = _.clone(incident)
      baseAnnotation.textOffsets = incident.annotations?.location[0].textOffsets
      baseAnnotation.type = if incident.accepted then "accepted" else "unaccepted"
      if incident.uncertainCountType
        baseAnnotation.type += " uncertain"
      baseAnnotation.attributes =
        'data-incident-id': incident._id
      return baseAnnotation
    html = annotateContent(content, _.compact(incidentAnnotations))
    new Spacebars.SafeString(html)

  buildAnnotatedIncidentSnippet: (content, incident) ->
    PADDING_CHARACTERS = 30
    incidentAnnotations = []
    for type, typeAnnotations of incident.annotations
      typeAnnotations.forEach (annotation) ->
        incidentAnnotations.push
          type: type
          textOffsets: annotation.textOffsets
    startingIndex = _.min(incidentAnnotations.map (a)-> a.textOffsets[0])
    startingIndex = Math.max(startingIndex - PADDING_CHARACTERS, 0)
    endingIndex = _.max(incidentAnnotations.map (a)-> a.textOffsets[1])
    endingIndex = Math.min(endingIndex + PADDING_CHARACTERS, content.length - 1)
    annotateContent(content, incidentAnnotations, {
      startingIndex: startingIndex
      endingIndex: endingIndex
    })
