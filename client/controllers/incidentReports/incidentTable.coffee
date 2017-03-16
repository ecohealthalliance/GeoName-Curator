{ notify } = require '/imports/ui/notification'

SCROLL_WAIT_TIME = 500
Template.incidentTable.onCreated ->
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

changeIncidentStatus = (status, instance) ->
  instance.data.incidents.find({selected: true}).forEach (incident) ->
    incident = _id: incident._id
    incident.accepted = status
    #setting accepted status of local collection as well
    Template.instance().data.incidents.update({_id: incident._id}, {$set: {accepted: status}})
    Meteor.call 'updateIncidentReport', incident, false, (error, result) ->
      if error
        notify('error', 'There was a problem updating your incident reports.')
        return

updateAllIncidentsStatus = (instance, status, event) ->
  instance.data.incidents.update {}, {$set: {selected: status}}, {multi: true}
  event.currentTarget.blur()

Template.incidentTable.helpers
  incidents: ->
    Template.instance().data.incidents.find({accepted: {$ne: false}})

  incidentsSelected: ->
    Template.instance().data.incidents.find({selected: true}).count() > 0

  allSelected: ->
    incidents = Template.instance().data.incidents
    incidents.find().count() == incidents.find({selected: true}).count()

Template.incidentTable.events
  'click table.incident-table tr td .select': (event, instance) ->
    event.stopPropagation()
    instance.data.incidents.update({_id: @_id}, {$set: {selected: !@selected}})

  'click .reject': (event, instance) ->
    changeIncidentStatus(false, instance)
    event.currentTarget.blur()

  'click .select-all': (event, instance) ->
    updateAllIncidentsStatus(instance, true, event)

  'click .deselect-all': (event, instance) ->
    updateAllIncidentsStatus(instance, false, event)

  'mouseover .incident-table tbody tr': (event, instance) ->
    if not instance.data.scrollToAnnotations
      return
    instance.scrollToAnnotation(@_id)

  'mouseout .incident-table tbody tr': (event, instance) ->
    if not instance.data.scrollToAnnotations
      return
    instance.stopScrollingInterval()

  'click .incident-table tbody tr': (event, instance) ->
    event.stopPropagation()
    source = instance.data.source
    Modal.show 'incidentModal',
      articles: [source]
      userEventId: null
      edit: true
      incident: @
      updateEvent: false
