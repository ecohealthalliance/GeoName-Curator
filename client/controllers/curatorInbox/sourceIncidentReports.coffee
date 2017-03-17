Template.sourceIncidentReports.onCreated ->
  @data.selectedIncidentTab.set(0)
  @tableContentScrollable = new ReactiveVar(true)

Template.sourceIncidentReports.helpers
  selectedIncidentTab: (tab) ->
    parseInt(tab) == Template.instance().data.selectedIncidentTab.get()

  tableContentScrollable: ->
    Template.instance().tableContentScrollable

  tableContentIsScrollable: ->
    Template.instance().tableContentScrollable.get()

Template.sourceIncidentReports.events
  'click .tabs a': (event, instance) ->
    instance.data.selectedIncidentTab.set(instance.$(event.currentTarget).data('tab'))

  'click .add-incident': (event, instance) ->
    Modal.show 'incidentModal',
      articles: [instance.data.source]
      add: true
      accept: true
