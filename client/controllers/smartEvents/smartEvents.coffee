{ manageTableSorting,
  tableFields,
  gotoEvent,
  scrollToTop } = require('/imports/reactiveTable')

Template.smartEvents.onCreated ->
  tableName = 'smart-events'
  @creatorFilter = new ReactiveTable.Filter('creatorFilter', ['createdByUserId'])
  @creatorFilter.set('')
  @showCurrentUserEvents = new ReactiveVar(false)
  @currentPage = new ReactiveVar(Session.get("#{tableName}-current-page") or 0)
  @rowsPerPage = new ReactiveVar(Session.get("#{tableName}-rows-per-page") or 10)
  @tableOptions =
    name: tableName
    fieldVisibility: {}
    sortOrder: {}
    sortDirection: {}
    fields: [
      {
        arrayName: ''
        description: 'The name of the EID.'
        displayName: 'Event Name'
        fieldName: 'eventName',
        defaultSortDirection: 1
      }
      {
        arrayName: '',
        displayName: 'Created By'
        description: 'User who created the event.'
        fieldName: 'createdByUserName'
        defaultSortDirection: 1
      }
      {
        arrayName: ''
        description: 'Date the event was last modified.'
        displayName: 'Last Modified Date'
        fieldName: 'lastModifiedDate'
        defaultSortDirection: -1
        displayFn: (value, object, key) ->
          if value != null
            content =  moment(value).format('MMM D, YYYY')
          else
            content =  "No date"
          new Spacebars.SafeString("<span data-heading='Last Modified Date'>#{content}</span>")
      }
    ]
  manageTableSorting(@)

Template.smartEvents.helpers
  settings: ->
    instance = Template.instance()

    id: "#{instance.tableOptions.name}-table"
    fields: tableFields(instance)
    currentPage: instance.currentPage
    rowsPerPage: instance.rowsPerPage
    showRowCount: true
    showColumnToggles: false
    showFilter: false
    class: 'table featured'
    filters: ['smartEventFilter', 'creatorFilter']
    showLoader: true
    noDataTmpl: Template.noResults

  searchSettings: ->
    id: 'smartEventFilter'
    classes: 'event-search page-options--search'
    tableId: "#{Template.instance().tableOptions.name}-table"
    placeholder: 'Search Smart Events'
    props: ['eventName']

  showCurrentUserEventsChecked: ->
    Template.instance().showCurrentUserEvents.get()

Template.smartEvents.events
  'click .reactive-table tbody tr': gotoEvent

  'click .next-page, click .previous-page': scrollToTop

  'click .show-current-user-events': (event, instance) ->
    filterSelector = ''
    creatorFilter = instance.creatorFilter
    showCurrentUserEvents = instance.showCurrentUserEvents
    if not creatorFilter.get()
      filterSelector = $eq: Meteor.userId()
    showCurrentUserEvents.set(not showCurrentUserEvents.get())
    creatorFilter.set(filterSelector)
    $(event.currentTarget).blur()
