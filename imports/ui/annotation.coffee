module.exports =
  annotateContent: (content, incidents) ->
    lastEnd = 0
    html = ''
    # Sort incidents by case annotation's poisiton in content
    _.sortBy(incidents, (incident) ->
      incident.annotations?.case[0].textOffsets[0]
    ).map (incident) ->
      textOffsets = incident.annotations?.case[0].textOffsets
      if textOffsets
        [start, end] = textOffsets
        html += (
          Handlebars._escape("#{content.slice(lastEnd, start)}") +
          """<span
            class='annotation annotation-text#{
              if incident.accepted then " accepted" else ""
            }#{
              if incident.uncertainCountType then " uncertain" else ""
            }'
            data-incident-id='#{incident._id}'
          >#{Handlebars._escape(content.slice(start, end))}</span>"""
        )
        lastEnd = end
    html += Handlebars._escape("#{content.slice(lastEnd)}")
    new Spacebars.SafeString(html)

  buildAnnotatedIncidentSnippet: (content, incident) ->
    displayCharacters = 150
    incidentAnnotations = []
    for type, typeAnnotations of incident.annotations
      typeAnnotations.forEach (annotation) ->
        incidentAnnotations.push
          type: type
          textOffsets: annotation.textOffsets

    startingIndex = _.min(incidentAnnotations.map (a)-> a.textOffsets[0])
    startingIndex = Math.max(startingIndex - 30, 0)
    endingIndex = _.max(incidentAnnotations.map (a)-> a.textOffsets[1])
    endingIndex = Math.min(endingIndex + 30, content.length - 1)
    lastOffset = startingIndex
    html = ""
    if incidentAnnotations[0]?.textOffsets[0] isnt 0
      html += "..."
    endpoints = []
    incidentAnnotations.map (annotation)->
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
        html += "</span>"
      if start
        activeAnnotations.push(annotation)
      else
        activeAnnotations = _.without(activeAnnotations, annotation)
      if activeAnnotations.length > 0
        types = activeAnnotations.map((a)-> a.type).join(" ")
        html += "<span class='annotation-text #{types}'>"
      lastOffset = offset
    html += Handlebars._escape("#{content.slice(lastOffset, endingIndex)}")
    if lastOffset < content.length - 1
      html += "..."
    html
