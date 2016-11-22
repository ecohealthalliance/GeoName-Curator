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

Template.addIncidentReport.events
  'click .open-incident-form': (event, instance) ->
    data = instance.data
    Modal.show 'incidentModal',
      articles: data.articles
      userEventId: data.userEvent._id
      add: true

Template.detailIcon.onRendered ->
  @$('[data-toggle=tooltip]').tooltip()
