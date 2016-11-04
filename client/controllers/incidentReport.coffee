import { formatUrl } from '/imports/utils.coffee'

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

Template.addIncidentReport.events
  'click .open-incident-form': (event, template) ->
    Modal.show('incidentModal', {articles: template.data.articles, userEventId: template.data.userEvent._id, add: true})
