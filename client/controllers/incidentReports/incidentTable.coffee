import Incidents from '/imports/collections/incidentReports.coffee'
import { notify } from '/imports/ui/notification'
import selectedIncidents from '/imports/selectedIncidents'
import { buildAnnotatedIncidentSnippet } from '/imports/ui/annotation'
SCROLL_WAIT_TIME = 500

_acceptedQuery = (accepted) ->
  query = {}
  if accepted
    query.accepted = true
  else if not _.isUndefined(accepted) and not accepted
    query.accepted = {$ne: true}
  query

_updateAllIncidentsStatus = (instance, select, event) ->
  query = _acceptedQuery(instance.accepted)
  if select
    Incidents.find(query).forEach (incident) ->
      selectedIncidents.insert
        id: incident._id
        accepted: incident.accepted
  else
    selectedIncidents.remove(query)
  event.currentTarget.blur()

_selectedIncidents = (instance) ->
  query = _acceptedQuery(instance.accepted)
  selectedIncidents.find(query)

_incidentsSelected = (instance) ->
  _selectedIncidents(instance).count()

select2NoResults = ->
  """
    <div class='no-results small'>
      <p>No Results Found</p>
    </div>
    <button class='btn btn-default add-new-event'>Add New Event</a>
  """

Template.incidentTable.onCreated ->
  @addingEvent = new ReactiveVar(false)
  @selectedEventId = new ReactiveVar(false)
  @tableContentScrollable = @data.tableContentScrollable
  @accepted = @data.accepted
  @scrollToAnnotation = (id) =>
    @stopScrollingInterval()
    $annotation = $("span[data-incident-id=#{id}]")
    $sourceTextContainer = $('.curator-source-details--copy')
    $("span[data-incident-id]").removeClass('viewing')
    appHeaderHeight = $('header nav.navbar').outerHeight()
    detailsHeaderHeight = $('.curator-source-details--header').outerHeight()
    headerOffset = appHeaderHeight + detailsHeaderHeight
    containerScrollTop = $sourceTextContainer.scrollTop()
    annotationTopOffset = $annotation.offset().top
    countainerVerticalMidpoint = $sourceTextContainer.height() / 2
    totalOffset = annotationTopOffset - headerOffset
    # Distance of scroll based on postition of text container, scroll position
    # within the text container and the container's midpoint (to position the
    # annotation in the center of the container)
    scrollDistance =  totalOffset + containerScrollTop - countainerVerticalMidpoint
    $sourceTextContainer.stop().animate
      scrollTop: scrollDistance
    , 500, -> $annotation.addClass('viewing')


  @stopScrollingInterval = ->
    clearInterval(@interval)

Template.incidentTable.onRendered ->
  @autorun =>
    if not _incidentsSelected(@)
      @addingEvent.set(false)
      @selectedEventId.set(null)

  @autorun =>
    incident = Incidents.findOne(_id: Router.current().params.incidentId)
    if incident
      source = @data.source
      snippetHtml = buildAnnotatedIncidentSnippet(source.content, incident, false)
      Modal.show 'suggestedIncidentModal',
        articles: [source]
        incident: incident
        incidentText: Spacebars.SafeString(snippetHtml)
        offCanvasStartPosition: 'top'
        showBackdrop: true

Template.incidentTable.helpers
  incidents: ->
    instance = Template.instance()
    query = _acceptedQuery(instance.accepted)
    query.url = {$regex: new RegExp("#{instance.data.source._sourceId}$")}
    incidents = Incidents.find(query).map (incident)->
      incident.snippet = Spacebars.SafeString(buildAnnotatedIncidentSnippet(instance.data.source.content, incident))
      incident
    _.sortBy(incidents, (i)-> i.annotations.location[0].textOffsets[0])

  allSelected: ->
    instance = Template.instance()
    selectedIncidentCount = _incidentsSelected(instance)
    query = _acceptedQuery(instance.accepted)
    Incidents.find(query).count() == selectedIncidentCount

  selected: ->
    selectedIncidents.findOne(id: @_id)

  incidentsSelected: ->
    _incidentsSelected(Template.instance())

  acceptance: ->
    not Template.instance().accepted

  action: ->
    if Template.instance().accepted
      'Reject'
    else
      'Accept'

  addEvent: ->
    Template.instance().addingEvent.get()

  selectedIncidents: ->
    _selectedIncidents(Template.instance())

  tableContentScrollable: ->
    Template.instance().tableContentScrollable

Template.incidentTable.events
  'click table.incident-table tr td .select': (event, instance) ->
    event.stopPropagation()
    query = id: @_id
    if selectedIncidents.findOne(query)
      selectedIncidents.remove(query)
    else
      query.accepted = @accepted
      selectedIncidents.insert(query)

  'click .action': (event, instance) ->
    accepted = instance.accepted
    accept = true
    if accepted
      accept = false
    selectedIncidents.find(_acceptedQuery(accepted)).forEach (incident) ->
      incident = _id: incident.id
      incident.accepted = accept
      Meteor.call 'updateIncidentReport', incident, (error, result) ->
        if error
          notify('error', 'There was a problem updating your incident reports.')
          return
    selectedIncidents.remove({})
    event.currentTarget.blur()

  'click .select-all': (event, instance) ->
    _updateAllIncidentsStatus(instance, true, event)

  'click .deselect-all': (event, instance) ->
    _updateAllIncidentsStatus(instance, false, event)

  'click .incident-table tbody .open-incident': (event, instance) ->
    event.stopPropagation()
    snippetHtml = buildAnnotatedIncidentSnippet(instance.data.source.content, @)
    Modal.show 'suggestedIncidentModal',
      articles: [instance.data.source]
      incident: @
      incidentText: Spacebars.SafeString(snippetHtml)
      offCanvasStartPosition: 'top'
      showBackdrop: true

  'click .view': (event, instance) ->
    instance.scrollToAnnotation(@_id)
