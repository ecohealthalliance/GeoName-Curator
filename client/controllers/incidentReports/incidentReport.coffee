import { formatUrl } from '/imports/utils.coffee'
import { pluralize } from '/imports/ui/helpers'

Template.incidentReport.helpers
  formatUrl: formatUrl

  caseCounts: ->
    @deaths or @cases

  deathsLabel: ->
    pluralize 'Death', @deaths, false

  casesLabel: ->
    pluralize 'Case', @cases, false

  importantDetails: ->
    @deaths or @cases or @status
