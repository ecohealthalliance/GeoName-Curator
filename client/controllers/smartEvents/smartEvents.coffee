Template.smartEvents.onCreated ->
  @creatorFilter = new ReactiveTable.Filter('creatorFilter', ['createdByUserName'])
  @showCurrentUserEvents = new ReactiveVar(false)

Template.smartEvents.onRendered ->
  @autorun =>
    if @showCurrentUserEvents.get()
      @creatorFilter.set(Meteor.user()?.profile.name)
    else
      @creatorFilter.set(null)

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
    filters: ['smartEventFilter', 'creatorFilter']
    showLoader: true
    noDataTmpl: Template.noResults

  searchSettings: ->
    id: 'smartEventFilter'
    classes: 'event-search page-options--search'
    tableId: 'smart-events-table'
    placeholder: 'Search Smart Events'
    props: ['eventName']

  showCurrentUserEventsChecked: ->
    Template.instance().showCurrentUserEvents.get()

Template.smartEvents.events
  'click .reactive-table tbody tr': (event) ->
    if event.metaKey
      url = Router.url "smart-event", _id: @_id
      window.open(url, "_blank")
    else
      Router.go "smart-event", _id: @_id

  'click .next-page, click .previous-page': ->
    if window.scrollY > 0 and window.innerHeight < 700
      $(document.body).animate({scrollTop: 0}, 400)

  'click .show-current-user-events': (event, instance) ->
    showCurrentUserEvents = instance.showCurrentUserEvents
    showCurrentUserEvents.set(not showCurrentUserEvents.get())
    $(event.currentTarget).blur()
