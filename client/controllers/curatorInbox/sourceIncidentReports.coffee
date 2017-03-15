Template.sourceIncidentReports.helpers
  selectedIncidentTab: (tab) ->
    parseInt(tab) == Template.instance().data.selectedIncidentTab.get()

Template.sourceIncidentReports.events
  'click .tabs a': (event, instance) ->
    instance.data.selectedIncidentTab.set(instance.$(event.currentTarget).data('tab'))
