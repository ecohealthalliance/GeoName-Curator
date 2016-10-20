Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'
Articles = require '/imports/collections/articles.coffee'

Template.curatorEvents.onCreated ->
  @eventFields = [
    {
      key: "expand"
      label: ""
      cellClass: "open-row"
    },
    {
      key: 'eventName'
      label: 'Event Name'
      sortDirection: 1
      hidden: false
    },
    {
      key: 'creationDate'
      label: 'Creation Date'
      sortOrder: 0
      sortDirection: -1
      hidden: true
    }
  ]
  @addEventMenuIsOpen = new ReactiveVar false
  @subscribe("articles", {
    url:
      $regex: "post\/" + @data._sourceId + "$"
  })
  @associatedEventIds = new ReactiveVar([])
  @autorun =>
    @associatedEventIds.set Articles.find(
      url:
        $regex: "post\/" + @data._sourceId + "$"
    ).map((article)-> article.userEventId)

Template.curatorEvents.helpers
  userEvents: ->
    UserEvents.find(
      _id:
        $nin: Template.instance().associatedEventIds.get()
    )

  associatedUserEvents: ->
    UserEvents.find(
      _id:
        $in: Template.instance().associatedEventIds.get()
    )

  associated: () ->
    articleId = Template.instance().data._id
    CuratorSources.findOne({ _id: articleId, relatedEvents: this._id })

  settings: ->
    fields = []
    for field in Template.instance().eventFields
      fields.push {
        key: field.key
        label: field.label
        cellClass: field.cellClass
        sortOrder: field.sortOrder || 99
        sortDirection: field.sortDirection || 99
        sortable: false
        hidden: field.hidden
      }

    return {
      id: 'curator-events-table'
      showColumnToggles: false
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showColumnToggles: false
      showRowCount: false
      currentPage: 1
      rowsPerPage: 5
      # showNavigation: 'never'
    }

  addEventMenuIsOpen: ->
    Template.instance().addEventMenuIsOpen.get()

Template.curatorEvents.events
  "click .curator-events-table .curator-events-table-row": (event, template) ->
    $target = $(event.target)
    $parentRow = $target.closest("tr")
    $currentOpen = template.$("tr.tr-incidents")
    closeRow = $parentRow.hasClass("incidents-open")
    if $currentOpen
      template.$("tr").removeClass("incidents-open")
      $currentOpen.remove()
    if not closeRow
      $tr = $("<tr id='tr-incidents'>").addClass("tr-incidents")
      $parentRow.addClass("incidents-open").after($tr)
      Blaze.renderWithData(Template.curatorEventIncidents, this, $tr[0])
  "click .open-add-event-form": (event, template) ->
    template.addEventMenuIsOpen.set !template.addEventMenuIsOpen.get()
  "click #associate-events tr": (event, template) ->
    Meteor.call('addEventSource', {
      url: "http://www.promedmail.org/post/" + template.data._sourceId,
      userEventId: @_id
      publishDate: template.data.publishDate
      publishDateTZ: "EST"
    })
