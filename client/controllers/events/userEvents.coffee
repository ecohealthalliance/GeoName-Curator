Template.userEvents.onCreated ->
  @userEventFields = [
    {
      arrayName: '',
      description: 'The name of the EID.',
      displayName: 'Event Name',
      fieldName: 'eventName',
      defaultSortDirection: 1
    }
    {
      arrayName: '',
      description: 'The number of articles associated with the event.',
      displayName: 'Article Count',
      fieldName: 'articleCount',
      defaultSortDirection: 1
      displayFn: (value, object, key) ->
        new Spacebars.SafeString("<span data-heading='Article Count'>#{value}</span>")
    }
    {
      arrayName: '',
      description: 'Date last incident occured.',
      displayName: 'Last Incident Date',
      fieldName: 'lastIncidentDate',
      defaultSortDirection: -1,
      displayFn: (value, object, key) ->
        if value != null
          content = moment(value).format('MMM D, YYYY')
        else
          content = "No incidents"
        new Spacebars.SafeString("<span data-heading='Last Incident Date'>#{content}</span>")
    },
    {
      arrayName: '',
      description: 'Date the event was last modified.',
      displayName: 'Last Modified Date',
      fieldName: 'lastModifiedDate',
      defaultSortDirection: -1,
      displayFn: (value, object, key) ->
        if value != null
          content =  moment(value).format('MMM D, YYYY')
        else
          content =  "No date"
        new Spacebars.SafeString("<span data-heading='Last Modified Date'>#{content}</span>")
    }
  ]

  @currentPage = new ReactiveVar(Session.get('events-current-page') or 0)
  @rowsPerPage = new ReactiveVar(Session.get('events-rows-per-page') or 10)
  @fieldVisibility = {}
  @sortOrder = {}
  @sortDirection = {}

  for field in @userEventFields
    oldVisibility = Session.get('events-field-visible-' + field.fieldName)
    visibility = if _.isUndefined(oldVisibility) then true else oldVisibility
    @fieldVisibility[field.fieldName] = new ReactiveVar(visibility)

    defaultSortOrder = Infinity
    oldSortOrder = Session.get('events-field-sort-order-' + field.fieldName)
    sortOrder = if _.isUndefined(oldSortOrder) then defaultSortOrder else oldSortOrder
    @sortOrder[field.fieldName] = new ReactiveVar(sortOrder)

    defaultSortDirection = field.defaultSortDirection
    oldSortDirection = Session.get('events-field-sort-direction-' + field.fieldName)
    sortDirection = if _.isUndefined(oldSortDirection) then defaultSortDirection else oldSortDirection
    @sortDirection[field.fieldName] = new ReactiveVar(sortDirection)

  @autorun =>
    Session.set 'events-current-page', @currentPage.get()
    Session.set 'events-rows-per-page', @rowsPerPage.get()
    for field in @userEventFields
      Session.set 'events-field-visible-' + field.fieldName, @fieldVisibility[field.fieldName].get()
      Session.set 'events-field-sort-order-' + field.fieldName, @sortOrder[field.fieldName].get()
      Session.set 'events-field-sort-direction-' + field.fieldName, @sortDirection[field.fieldName].get()

Template.userEvents.helpers
  settings: ->
    fields = []
    for field in Template.instance().userEventFields
      tableField =
        key: field.fieldName
        label: field.displayName
        isVisible: Template.instance().fieldVisibility[field.fieldName]
        sortOrder: Template.instance().sortOrder[field.fieldName]
        sortDirection: Template.instance().sortDirection[field.fieldName]
        sortable: not field.arrayName

      if field.displayFn
        tableField.fn = field.displayFn
      fields.push(tableField)

    id: 'user-events-table'
    showColumnToggles: true
    fields: fields
    currentPage: Template.instance().currentPage
    rowsPerPage: Template.instance().rowsPerPage
    showRowCount: true
    showColumnToggles: false
    showFilter: false
    class: 'table featured'
    filters: ['eventFilter']

  textFilter: ->
    Template.instance().textFilter

  searchSettings: ->
    id:"eventFilter"
    classes: 'event-search page-options--search'
    textFilter: Template.instance().textFilter
    tableId: 'user-events-table'
    placeholder: 'Search Events'
    props: ['eventName']

Template.userEvents.events
  "click .reactive-table tbody tr": (event) ->
    if event.metaKey
      url = Router.url "user-event", {_id: @_id}
      window.open(url, "_blank")
    else
      Router.go "user-event", {_id: @_id}

  "click .next-page, click .previous-page": ->
    if (window.scrollY > 0 and window.innerHeight < 700)
      $(document.body).animate({scrollTop: 0}, 400)
