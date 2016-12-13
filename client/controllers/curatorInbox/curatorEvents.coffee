Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'
Articles = require '/imports/collections/articles.coffee'

Template.curatorEvents.onCreated ->
  instance = @
  @suggestedEventsHeaderState = new ReactiveVar true
  @autorun =>
    instance.subscribe "articles",
      url:
        $regex: "post\/" + CuratorSources.findOne(@data.selectedSourceId.get())._sourceId + "$"
    instance.associatedEventIdsToArticles = new ReactiveVar {}

  @autorun =>
    @associatedEventIdsToArticles.set _.object(Articles.find(
      url:
        $regex: "post\/" + CuratorSources.findOne(@data.selectedSourceId.get())._sourceId + "$"
    ).map((article)->
      [article.userEventId, article]
    ))

Template.curatorEvents.helpers
  userEvents: ->
    UserEvents.find
      _id:
        $nin: _.keys(Template.instance().associatedEventIdsToArticles.get())

  associatedUserEvents: ->
    UserEvents.find
      _id:
        $in: _.keys(Template.instance().associatedEventIdsToArticles.get())

  associatedEventIdsToArticles: ->
    Template.instance().associatedEventIdsToArticles

  title: ->
    Template.instance().data.title

  associated: () ->
    articleId = Template.instance().data._id
    CuratorSources.findOne({ _id: articleId, relatedEvents: this._id })

  settings: ->
    id: 'curator-events-table'
    class: 'table curator-events-table'
    fields: [
      {
        key: 'eventName'
        label: 'Event Name'
        sortDirection: 1
        tmpl: Template.curatorEventSearchRow
      }
      {
        key: 'creationDate'
        label: 'Creation Date'
        sortOrder: 0
        sortDirection: -1
        hidden: true
      }
    ]
    filters: ['curatorEventsFilter']
    noDataTmpl: Template.noCuratorEvents
    showNavigationRowsPerPage: false
    showColumnToggles: false
    showRowCount: false
    currentPage: 1
    rowsPerPage: 5
    class: 'curator-events-table static-rows table'

  allEventsOpen: ->
    Template.instance().suggestedEventsHeaderState.get()

  searchSettings: ->
    id: 'curatorEventsFilter'
    textFilter: Template.instance().textFilter
    placeholder: 'Search Events'
    searching: new ReactiveVar false
    toggleable: true

Template.curatorEvents.events
  'click .curator-events-table .curator-events-table-row': (event, instance) ->
    $target = $(event.target)
    $parentRow = $target.closest('tr')
    $currentOpen = instance.$('tr.tr-incidents')
    closeRow = $parentRow.hasClass('incidents-open')
    if $currentOpen
      instance.$('tr').removeClass('incidents-open')
      $currentOpen.remove()
    if not closeRow
      $tr = $("<tr id='tr-incidents'>").addClass("tr-incidents")
      $parentRow.addClass('incidents-open').after($tr)
      Blaze.renderWithData(Template.curatorEventIncidents, this, $tr[0])

  'click .associate-event': (event, instance) ->
    source = CuratorSources.findOne(instance.data.selectedSourceId.get())
    Meteor.call 'addEventSource',
      url: "promedmail.org/post/#{source._sourceId}"
      userEventId: @_id
      title: source.title
      publishDate: source.publishDate
      publishDateTZ: 'EST'

  'click .disassociate-event': (event, instance) ->
    Meteor.call('removeEventSource', instance.associatedEventIdsToArticles.get()[@_id])

  'click .suggest-incidents': (event, instance) ->
    Modal.show('suggestedIncidentsModal', {
        userEventId: @_id
        article: instance.associatedEventIdsToArticles.get()[@_id]
      })

  'click .curator-events-header.all-events': (event, instance) ->
    suggestedEventsHeaderState = instance.suggestedEventsHeaderState
    suggestedEventsHeaderState.set not suggestedEventsHeaderState.get()

  'click #curatorEventsFilter': (event, instance) ->
    event.stopPropagation()
    instance.suggestedEventsHeaderState.set true

  "click .add-new-event": (event, instance) ->
    Modal.show 'editEventDetailsModal',
      action: 'add'
      saveActionMessage: 'Add Event & Associate with Source'
      addToSource: true
      sourceId: instance.data.selectedSourceId.get()
      eventName: $('#curatorEventsFilter input').val().trim() or ''
