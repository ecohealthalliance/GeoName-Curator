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
      id: 'article-curation-events-table'
      showColumnToggles: false
      fields: fields
      showRowCount: true
      showFilter: false
      currentPage: Template.instance().currentPage
      rowsPerPage: Template.instance().rowsPerPage
      showNavigation: 'never'
    }

Template.curatorEvents.events
  "click .curator-events-table tbody tr": (event, template) ->
    console.log 'open'
    alert 'OPEN'
    # $target = $(event.target)
    # $parentRow = $target.closest("tr")
    # $currentOpen = template.$("tr.tr-cases")
    # closeRow = $parentRow.hasClass("cases-open")
    # if $currentOpen
    #   template.$("tr").removeClass("cases-open")
    #   $currentOpen.remove()
    # if not closeRow
    #   $tr = template.$("<tr>").addClass("tr-cases").html(Blaze.toHTMLWithData(Template.incidentReport, this))
    #   $parentRow.addClass("cases-open").after($tr)
  # "click .curator-events-table tbody tr": (event, template) ->
  #   template.$("tr").removeClass("cases-open")
  #   template.$("tr.tr-cases").remove()