Template.addIncidentReport.events
  'click .open-incident-form': (event, template) ->
    Modal.show('incidentModal', {articles: template.data.articles, userEventId: template.data.userEvent._id, add: true})
