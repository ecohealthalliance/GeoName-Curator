formatVal = =>
  @grid.Events.formatVal.apply(@, arguments)

Template.events.onCreated ->
  @currentPage = new ReactiveVar(Session.get('events-current-page') or 0)
  @rowsPerPage = new ReactiveVar(Session.get('events-rows-per-page') or 10)

  fields = @data.fields.fetch()
  @fieldVisibility = {}
  @sortOrder = {}
  @sortDirection = {}
  for field in fields
    defaultVisibility = field['Event table'] is '2'
    oldVisibility = Session.get('events-field-visible-' + field.spreadsheetName)
    visibility = if _.isUndefined(oldVisibility) then defaultVisibility else oldVisibility
    @fieldVisibility[field.spreadsheetName] = new ReactiveVar(visibility)

    defaultSortOrder = Infinity
    oldSortOrder = Session.get('events-field-sort-order-' + field.spreadsheetName)
    sortOrder = if _.isUndefined(oldSortOrder) then defaultSortOrder else oldSortOrder
    @sortOrder[field.spreadsheetName] = new ReactiveVar(sortOrder)

    defaultSortDirection = 1
    oldSortDirection = Session.get('events-field-sort-direction-' + field.spreadsheetName)
    sortDirection = if _.isUndefined(oldSortDirection) then defaultSortDirection else oldSortDirection
    @sortDirection[field.spreadsheetName] = new ReactiveVar(sortDirection)

  @autorun =>
    Session.set 'events-current-page', @currentPage.get()
    Session.set 'events-rows-per-page', @rowsPerPage.get()
    for field in @data.fields.fetch()
      Session.set 'events-field-visible-' + field.spreadsheetName, @fieldVisibility[field.spreadsheetName].get()
      Session.set 'events-field-sort-order-' + field.spreadsheetName, @sortOrder[field.spreadsheetName].get()
      Session.set 'events-field-sort-direction-' + field.spreadsheetName, @sortDirection[field.spreadsheetName].get()


Template.events.helpers
  settings: ->
    fields = []
    for field in @fields.fetch()
      do (field) ->
        fields.push
          key: field.spreadsheetName
          label: field.displayName
          isVisible: Template.instance().fieldVisibility[field.spreadsheetName]
          sortOrder: Template.instance().sortOrder[field.spreadsheetName]
          sortDirection: Template.instance().sortDirection[field.spreadsheetName]
          sortable: not field.arrayName
          fn: (val, object) ->
            if field.arrayName
              array = object[field.arrayName] or []
              output = _.unique(element[field.spreadsheetName] for element in array).join(", ")
            else
              output = val or ''

            # hide Not Found/Not Applicable
            if output in ['Not Found', 'Not Applicable']
              output = ''

            # value should be hidden
            if output in field.valuesToHide
              output = ''

            # capitalize first letter
            if output.length > 1
              output = output.charAt(0).toUpperCase() + output.slice(1)

            # truncate long fields
            if output.length > 100
              output = output.slice(0, 100) + '...'

            # put empty values at the end
            if output is '' then sort = 2 else sort = 1

            output = formatVal(field.spreadsheetName, output, object)
            new Spacebars.SafeString("<span sort=#{sort}>#{output}</span>")

    {
      id: 'events-table'
      showColumnToggles: true
      fields: fields
      currentPage: Template.instance().currentPage
      rowsPerPage: Template.instance().rowsPerPage
      showRowCount: true
    }

Template.events.events
  "click .reactive-table tbody tr": (event) ->
    if event.metaKey
      url = Router.url "event", { eidID: @eidID }
      window.open(url, "_blank")
    else
      Router.go "event", { eidID: @eidID }
  "click .next-page, click .previous-page": ->
    if (window.scrollY > 0 and window.innerHeight < 700)
      $(document.body).animate({scrollTop: 0}, 400)
