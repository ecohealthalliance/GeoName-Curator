module.exports =
  annotateContent: (content, incidents) ->
    lastEnd = 0
    html = ''
    incidents.map (incident)->
      textOffsets = incident.annotations?.case.textOffsets[0][0]
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
    for type, annotations of incident.annotations
      annotations.textOffsets?.forEach (offsets) ->
        incidentAnnotations.push
          type: type
          textOffsets: offsets

    startingIndex = _.min(incidentAnnotations.map (a)-> a.textOffsets[0][0])
    startingIndex = Math.max(startingIndex - 30, 0)
    endingIndex = _.max(incidentAnnotations.map (a)-> a.textOffsets[0][1])
    endingIndex = Math.min(endingIndex + 30, content.length - 1)
    lastEnd = startingIndex
    html = ""
    if incidentAnnotations[0]?.textOffsets[0][0] isnt 0
      html += "..."
    incidentAnnotations.map (annotation)->
      [start, end] = annotation.textOffsets[0]
      type = annotation.type
      html += (
        Handlebars._escape("#{content.slice(lastEnd, start)}") +
        """<span class='annotation-text #{type}'>#{
          Handlebars._escape(content.slice(start, end))
        }</span>"""
      )
      lastEnd = end
    html += Handlebars._escape("#{content.slice(lastEnd, endingIndex)}")
    if lastEnd < content.length - 1
      html += "..."
    html
