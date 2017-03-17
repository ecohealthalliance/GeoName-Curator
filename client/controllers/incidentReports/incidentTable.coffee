UserEvents = require '/imports/collections/userEvents.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
{ notify } = require '/imports/ui/notification'
SCROLL_WAIT_TIME = 500

updateAllIncidentsStatus = (instance, status, event) ->
  selectedIncidents = instance.selectedIncidents
  if status
    Incidents.find().forEach (incident) ->
      selectedIncidents.insert
        id: incident._id
  else
    selectedIncidents.remove({})
  event.currentTarget.blur()

Template.incidentTable.onCreated ->
  @subscribe('useEvents')
  @subscribe('curatorSourceIncidentReports', @data.source._sourceId)
  @selectedIncidents = new Meteor.Collection(null)
  @addingEvent = new ReactiveVar(false)
  @eventSelected = new ReactiveVar(false)

  @scrollToAnnotation = (id) =>
    intervalTime = 0
    @interval = setInterval =>
      if intervalTime >= SCROLL_WAIT_TIME
        @stopScrollingInterval()
        $annotation = $("span[data-incident-id=#{id}]")
        $sourceTextContainer = $('.curator-source-details--copy')
        if window.innerWidth >= 1500 # In side-by-side view
          $sourceTextContainer = $('.curator-source-details--copy-wrapper')
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
      intervalTime += 100
    , 100

  @stopScrollingInterval = ->
    clearInterval(@interval)

Template.incidentTable.onRendered ->
  # If showing accepted IRs instantiate select2 input and register event to
  # show 'Create Event' modal
  if @data.accepted
    @autorun =>
      if @addingEvent.get() and @data.incidents.find({selected: true}).count()
        Meteor.defer =>
          events = UserEvents.find {},
            fields: eventName: 1
            sort: eventName: 1
          $select2 = @$('.select2')
          select2Data = events.map (event) ->
            id: event._id
            text: event.eventName
          $select2.select2
            data: select2Data
            placeholder: 'Search for an Event...'
            minimumInputLength: 0
            language:
              noResults: ->
                """
                  <div class='no-results small'>
                    <p>No Results Found</p>
                  </div>
                  <button class='btn btn-default add-new-event'>Add New Event</a>
                """
            escapeMarkup: (markup) -> markup

          $(document).on 'click', '.add-new-event', (event) =>
            $select2.select2('close')
            Modal.show 'editEventDetailsModal',
              action: 'add'
              saveActionMessage: 'Add Event & Associate Incident Reports'
              sourceId: @data.sourceId
              eventName: ''
  @autorun =>
    if not @data.incidents.find({selected: true}).count()
      @addingEvent.set(false)
      @eventSelected.set(null)

Template.incidentTable.onDestroyed ->
  $(document).off('click', '.add-new-event')

Template.incidentTable.helpers
  incidents: ->
    instance = Template.instance()
    accepted = instance.data.accepted
    query = {}
    query.url = {$regex: new RegExp("#{instance.data.source._sourceId}$")}
    if accepted
      query.accepted = true
    else if not _.isUndefined(accepted) and not accepted
      query.accepted = {$ne: true}
    Incidents.find(query)

  incidentsSelected: ->
    Template.instance().selectedIncidents.find().count() > 0

  allSelected: ->
    selectedIncidentCount = Template.instance().selectedIncidents.find().count()
    Incidents.find().count() == selectedIncidentCount

  selected: ->
    Template.instance().selectedIncidents.findOne(id: @_id)

  acceptance: ->
    not Template.instance().data.accepted

  action: ->
    if Template.instance().data.accepted
      'Reject'
    else
      'Accept'

  addEvent: ->
    Template.instance().addingEvent.get()

  allowAddingEvent: ->
    Template.instance().eventSelected.get()

Template.incidentTable.events
  'click table.incident-table tr td .select': (event, instance) ->
    event.stopPropagation()
    selectedIncidents = instance.selectedIncidents
    query = id: @_id
    if selectedIncidents.findOne(query)
      selectedIncidents.remove(query)
    else
      selectedIncidents.insert(query)

  'click .action': (event, instance) ->
    accept = true
    if instance.data.accepted
      accept = false
    selectedIncidents = instance.selectedIncidents
    selectedIncidents.find().forEach (incident) ->
      incident = _id: incident.id
      incident.accepted = accept
      Meteor.call 'updateIncidentReport', incident, (error, result) ->
        if error
          notify('error', 'There was a problem updating your incident reports.')
          return
    selectedIncidents.remove({})
    event.currentTarget.blur()

  'click .add': (event, instance) ->
    instance.data.incidents.find({selected: true}).forEach (incident) ->
      incident = _id: incident._id
      incident.userEventId = Template.instance().data.sourceId.get()._str
      Meteor.call 'updateIncidentReport', incident, false, (error, result) ->
        if error
          notify('error', 'There was a problem updating your incident reports.')
          return
      event.currentTarget.blur()

  'click .select-all': (event, instance) ->
    updateAllIncidentsStatus(instance, true, event)

  'click .deselect-all': (event, instance) ->
    updateAllIncidentsStatus(instance, false, event)

  'mouseover .incident-table tbody tr': (event, instance) ->
    if not instance.data.scrollToAnnotations or not @textOffsets
      return
    instance.scrollToAnnotation(@_id)

  'mouseout .incident-table tbody tr': (event, instance) ->
    if not instance.data.scrollToAnnotations or not @textOffsets
      return
    instance.stopScrollingInterval()

  'click .incident-table tbody tr': (event, instance) ->
    event.stopPropagation()
    Modal.show 'incidentModal',
      articles: [instance.data.source]
      userEventId: null
      edit: true
      incident: @
      updateEvent: false

  'click .show-addEvent': (event, instance) ->
    addingEvent = instance.addingEvent
    addingEvent.set(not addingEvent.get())
    event.currentTarget.blur()

  'select2:select': (event, instance) ->
    instance.eventSelected.set(event.params.data.id)
