Template.curatorEvents.onCreated ->
  @eventFields = [
    {
      key: "expand"
      label: ""
      cellClass: "open-row"
    },
    {
      key: 'eventName'
      label: 'Event Name',
      sortDirection: 1,
      hidden: false
    },
    {
      key: 'creationDate'
      label: 'Creation Date',
      sortOrder: 0
      sortDirection: -1
      hidden: true
    }
  ]

  @currentPage = new ReactiveVar(Session.get('curator-events-current-page') or 0)
  @rowsPerPage = new ReactiveVar(Session.get('curator-events-rows-per-page') or 5)

  @autorun =>
    Session.set 'curator-events-current-page', @currentPage.get()
    Session.set 'curator-events-rows-per-page', @rowsPerPage.get()

Template.curatorEvents.helpers
  userEvents: ->
    return grid.UserEvents.find()

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
      showRowCount: true
      showFilter: false
      currentPage: Template.instance().currentPage
      rowsPerPage: Template.instance().rowsPerPage
      showNavigation: 'never'
    }

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

Template.curatorEventIncidents.onCreated ->
  Meteor.subscribe "eventIncidents", @data._id

Template.curatorEventIncidents.helpers
  incidents: ->
    return grid.Incidents.find()

  settings: ->
    fields = [
      {
        key: "count"
        label: "Incident"
        fn: (value, object, key) ->
          if object.cases
            return object.cases + " case" + (if object.cases isnt "1" then "s" else "")
          else if object.deaths
            return object.deaths + " death" + (if object.deaths isnt "1" then "s" else "")
          else
            return object.specify
      },
      {
        key: "locations"
        label: "Locations"
        fn: (value, object, key) ->
          if object.locations
            return $.map(object.locations, (element, index) ->
              return element.displayName
            ).toString()
          return ""
      },
      {
        key: "dateRange"
        label: "Date"
        fn: (value, object, key) ->
          dateFormat = "M/D/YYYY"
          if object.dateRange?.type is "day"
            if object.dateRange.cumulative
              return "Before " + moment(object.dateRange.end).format(dateFormat)
            else
              return moment(object.dateRange.start).format(dateFormat)
          else if object.dateRange?.type is "precise"
            return moment(object.dateRange.start).format(dateFormat) + " - " + moment(object.dateRange.end).format(dateFormat)
          return ""
      },
      {
        key: "delete"
        label: ""
        cellClass: "remove-row"
      },
      {
        key: "Edit"
        label: ""
        cellClass: "edit-row"
      }
    ]

    return {
      id: 'curator-event-incidents-table'
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showRowCount: false
      class: "table"
      showColumnToggles: false
    }

Template.curatorEventIncidents.events
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    $parentRow = $target.closest("tr")
    currentOpen = template.$("tr.tr-details")
    if $target.closest(".remove-row").length
      if window.confirm("Are you sure you want to delete this incident report?")
        currentOpen.remove()
        Meteor.call("removeIncidentReport", @_id)
    else if $target.closest(".edit-row").length
      console.log template
      console.log this
      Modal.show("incidentModal", {
        articles: template.data.articles,
        userEventId: this.userEventId,
        edit: true,
        incident: this
        })