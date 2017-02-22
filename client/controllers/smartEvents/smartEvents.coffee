Template.smartEvents.helpers
  settings: ->
    fields = [
      {
        label: 'Event Name'
        key: 'eventName'
      }
      {
        label: 'Created By'
        key: 'createdByUserName'
      }
      {
        label: 'Last Modified Date'
        key: 'lastModifiedDate'
        displayFn: (value, object, key) ->
          if value != null
            content =  moment(value).format('MMM D, YYYY')
          else
            content =  "No date"
          new Spacebars.SafeString("<span data-heading='Last Modified Date'>#{content}</span>")
      }
    ]
    id: 'smart-events-table'
    fields: fields
    showColumnToggles: false
    showRowCount: true
    showFilter: false
    class: 'table featured'
    filters: ['smartEventFilter']
    showLoader: true
    noDataTmpl: Template.noResults

  textFilter: ->
    Template.instance().textFilter

  searchSettings: ->
    id: 'smartEventFilter'
    classes: 'event-search page-options--search'
    textFilter: Template.instance().textFilter
    tableId: 'smart-events-table'
    placeholder: 'Search Smart Events'
    props: ['eventName']

Template.smartEvents.events
  "click .reactive-table tbody tr": (event) ->
    if event.metaKey
      url = Router.url "smart-event", _id: @_id
      window.open(url, "_blank")
    else
      Router.go "smart-event", _id: @_id

  "click .next-page, click .previous-page": ->
    if window.scrollY > 0 and window.innerHeight < 700
      $(document.body).animate({scrollTop: 0}, 400)
