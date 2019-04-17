import Incidents from '/imports/collections/incidentReports.coffee'
import { buildAnnotatedIncidentSnippet } from '/imports/ui/annotation'
import notify from '/imports/ui/notification'
import selectedIncidents from '/imports/selectedIncidents'

Template.annotationOptions.onCreated ->
  data = @data
  @incident = Incidents.findOne(data.incidentId)

Template.annotationOptions.helpers
  incidentSelected: ->
    instance = Template.instance()
    selectedIncidents.findOne(id: @incidentId)

  incidentAccepted: ->
    Template.instance().incident.accepted

Template.annotationOptions.events
  'click .select': (event, instance) ->
    incidentId = instance.data.incidentId
    query = id: incidentId
    if selectedIncidents.findOne(query)
      selectedIncidents.remove(query)
    else
      query.accepted = true
      selectedIncidents.insert(query)

  'click .edit': (event, instance) ->
    source = instance.data.source
    incident = instance.incident
    snippetHtml = buildAnnotatedIncidentSnippet(
      source.enhancements.source.cleanContent.content, incident
    )
    Modal.show 'suggestedIncidentModal',
      articles: [source]
      incident: incident
      incidentText: Spacebars.SafeString(snippetHtml)
      offCanvasStartPosition: 'top'
      showBackdrop: true

  'click .delete': (event, instance) ->
    Meteor.call 'updateIncidentReport', {
      _id: instance.data.incidentId
      accepted: false
    }, (error, result) ->
      if error
        notify('error', 'There was a problem updating your incidents.')
