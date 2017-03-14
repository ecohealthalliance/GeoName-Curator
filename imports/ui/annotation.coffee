module.exports =
  annotateContent: (content, incidents) ->
    lastEnd = 0
    html = ''
    incidents.map (incident)->
      if incident.textOffsets
        [start, end] = incident.textOffsets or incident.countAnnotation.textOffsets[0]
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
      else
        Handlebars._escape(content.slice(start, end))
      lastEnd = end
    html += Handlebars._escape("#{content.slice(lastEnd)}")
    new Spacebars.SafeString(html)
