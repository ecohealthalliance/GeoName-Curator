{ annotateContent } = require('/imports/ui/annotation')

Template.annotatedContent.helpers
  annotatedContent: ->
    annotateContent(@content, @incidents.fetch())
