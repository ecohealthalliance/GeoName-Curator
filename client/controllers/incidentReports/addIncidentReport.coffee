Template.addIncidentReport.events
  'click .open-incident-form': (event, instance) ->
    data = instance.data
    Modal.show 'incidentModal',
      articles: data.articles
      userEventId: data.userEvent._id
      add: true
