fields = =>
  @grid.Fields

references = =>
  @grid.References

getVal = (key, object) =>
  @grid.Events.formatVal(key, object[key], object)


Template.statsTable.helpers
  showStat: (key, object) ->
    field = grid.Fields.findOne {"spreadsheetName": key}
    if field.Quotations isnt 0
      quote = @Quotations
    if object[key] isnt 'undefined' and
       object[key] isnt '' and
       object[key] isnt 'Not Applicable' and
       object[key] isnt 'Not Found' and
       object[key] not in field.valuesToHide
      object[key]
    else if object[key] is 'Not Found' and object[quote] and (object[quote] isnt 'undefined' or object[quote] isnt '')
      object[key]

  getVal: getVal

  getQuote: (event) ->
    if @Quotations isnt 0 and @Quotations isnt ''
      quotes = getVal(@Quotations, event)
      if quotes
        quotes.trim()

  getReference: (event) ->
    fieldName = @spreadsheetName.slice(0, -3) # cut off "Val"
    zoteroIds = event.references[fieldName]
    refs = _.map zoteroIds, (zoteroIdOrString) ->
      references().findOne({zoteroId: zoteroIdOrString})?.title or zoteroIdOrString
    refs.join("; ")

Template.tables.helpers
  checkStats: (table, event) ->
    values = []
    table.forEach (t) ->
      value = getVal(t.spreadsheetName, event)
      if (value and value isnt 'Not Found' and value isnt 'Not Applicable')
        values.push(value)
    values.length > 0

  getNotFound: (event) ->
    notFound = []
    for key, value of event when value is "Not Found"
      info = fields().findOne({"spreadsheetName": key})
      if info
        notFound.push
          name: info.displayName
          description: info.description
    notFound

  stats: ->
    fields().find({"tab": "Descriptive Epidemiology"}, {"sort": {"order": 1}})

  pathogenStats: ->
    fields().find({"tab": "Pathogen Taxonomy"}, {"sort": {"order": 1}})

  locationStats: ->
    fields().find({"tab": "Location"}, {"sort": {"order": 1}})

  economicsStats: ->
    fields().find({"tab": "Economics"}, {"sort": {"order": 1}})

Template.author.helpers
  formatAuthor: ->
    @creators[0].lastName

Template.reference.helpers
  isPMCID: ->
    @archive is 'PMCID'

  isPMID: ->
    @archive is 'PMID'
