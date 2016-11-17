Articles = require '/imports/collections/articles'

Template.location.onRendered ->
  sourceUrl = @data.source
  @$('[data-toggle=tooltip]').tooltip()

Template.location.helpers
  sourceName: (sourceUrl) ->
    Articles.findOne(url: sourceUrl).title
