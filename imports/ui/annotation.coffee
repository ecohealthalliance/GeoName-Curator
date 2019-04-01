annotateContent = (content, annotations, options={})->
  { startingIndex, endingIndex, tag } = options
  if not startingIndex
    startingIndex = 0
  if not endingIndex
    endingIndex = content.length
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
      isStart: true
    endpoints.push
      offset: end
      otherEndpointOffset: start
      annotation: annotation
      isStart: false
  endpoints = endpoints.sort (a, b)->
    if a.offset < b.offset
      -1
    else if a.offset > b.offset
      1
    else if a.isStart < b.isStart
      -1
    else if a.isStart > b.isStart
      1
    else if a.otherEndpointOffset < b.otherEndpointOffset
      1
    else if a.otherEndpointOffset > b.otherEndpointOffset
      -1
    else
      0
  activeAnnotations = []
  endpointGroups = []
  endpoints.forEach (endpoint)->
    {offset, annotation, isStart, otherEndpointOffset} = endpoint
    lastGroup = endpointGroups.slice(-1)[0]
    if lastGroup?.offset == offset and lastGroup?.isStart == isStart
      lastGroup.endpoints.push(endpoint)
    else
      endpointGroups.push(
        offset: offset
        isStart: isStart
        endpoints: [endpoint]
      )
  endpointGroups.forEach ({offset, isStart, endpoints})->
    html += Handlebars._escape(content.slice(lastOffset, offset))
    activeAnnotations.reverse().forEach (activeAnnotation)->
      html += "</#{activeAnnotation.tag or tag}>"
    endpoints.forEach ({annotation})->
      if isStart
        activeAnnotations.push(annotation)
        # Resort activeAnnotation to ensure accepted annotations are at the end
        acceptedAnnotations = []
        unacceptedAnnotations = []
        activeAnnotations.forEach (activeAnnotation) ->
          if activeAnnotation.type == "accepted"
            acceptedAnnotations.push(activeAnnotation)
          else
            unacceptedAnnotations.push(activeAnnotation)
        activeAnnotations = unacceptedAnnotations.concat(acceptedAnnotations)
      else
        activeAnnotations = _.without(activeAnnotations, annotation)
    activeAnnotations.forEach (activeAnnotation, idx)->
      types = activeAnnotations.map((a)->
        if a.ignore
          'ignore'
        else
          a.type
      ).filter((a)->a).join(" ")
      attributes = {}
      activeAnnotations.slice(0, idx + 1).forEach (a)->
        _.extend(attributes, a?.attributes or {})
      attributeText = _.map(attributes, (value, key)-> "#{key}='#{value}'").join(" ")
      classAttr = if types then "class='annotation annotation-text #{types}'" else ""
      html += "<#{activeAnnotation.tag or tag} #{classAttr} #{attributeText}>"
    lastOffset = offset
  html += Handlebars._escape("#{content.slice(lastOffset, endingIndex)}")
  if endingIndex < content.length
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
