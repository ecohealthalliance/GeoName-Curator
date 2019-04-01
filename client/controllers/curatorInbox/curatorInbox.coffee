CuratorSources = require '/imports/collections/curatorSources.coffee'
{ keyboardSelect } = require '/imports/utils'

uniteReactiveTableFilters = (filters) ->
  reactiveFilters = []
  _.each filters, (filter) ->
    _filter = filter.get()
    if _filter
      reactiveFilters.push _.object filter.fields.map (field)->
        [field, _filter]
  reactiveFilters

###
# prevents checking the scrollTop more than every 50 ms to avoid flicker
# if the scrollTop is greater than zero, show the 'back-to-top' button
#
# @param [object] scrollableElement, the dom element from the scroll event
###
debounceCheckTop = _.debounce (scrollableElement) ->
    top = $(scrollableElement).scrollTop()
    if top > 0
      $('.back-to-top').fadeIn()
    else
      $('.back-to-top').fadeOut()
, 50

Template.curatorInbox.onDestroyed ->
  # cleanup the event handler
  $('.curator-inbox-sources').off 'scroll'

Template.curatorInbox.onCreated ->
  @ready = new ReactiveVar(true)
  @selectedArticle = false
  @textFilter =
    new ReactiveTable.Filter('curator-inbox-article-filter', ['title'])
  @reviewFilter =
    new ReactiveTable.Filter('curator-inbox-review-filter', ['reviewed'])
  @reviewFilter.set(null)
  @selectedSourceId = new ReactiveVar(null)
  @query = new ReactiveVar(null)
  @currentPaneInView = new ReactiveVar('')
  @filtering = new ReactiveVar(false)
  @sourceCount = new ReactiveVar 0
  @curatorInboxFields = [
    {
      key: 'reviewed'
      description: 'Article has been curated'
      label: ''
      cellClass: (value) ->
        if value
          'curator-inbox-curated-row'
      sortDirection: -1
      sortOrder: 0
      fn: (value) ->
        ''
    },
    {
      key: 'title'
      description: 'The source\'s title.'
      label: 'Title'
      sortDirection: -1
    },
    {
      key: 'reviewedDate'
      description: 'Date the article was reviewed.'
      label: 'Reviewed'
      sortOrder: 1
      sortDirection: -1
      sortFn: (value, ctx)->
        value
      fn: (value) ->
        momentValue = moment(value)
        if not momentValue.isValid()
          return ""
        else if momentValue.diff(new Date(), 'days') > -7
          momentValue.fromNow()
        else
          momentValue.format('YYYY-MM-DD')
    }, {
      key: 'addedDate'
      description: 'Date the article was added.'
      label: 'Added'
      sortDirection: -1
      hidden: true
      fn: (value) ->
        moment(value).format('YYYY-MM-DD')
    },
    {
      key: 'expand'
      label: ''
      cellClass: 'action open-right'
    }
  ]

Template.curatorInbox.onRendered ->
  # determine if our `back-to-top` button should be initially displayed
  $scrollableElement = $('.curator-inbox-sources')
  debounceCheckTop($scrollableElement)
  # fadeIn/Out the `back-to-top` button based on if the div has scrollable content
  $scrollableElement.on 'scroll', ->
    debounceCheckTop(@)

  @autorun =>
    articleId = Router.current().params.articleId
    if articleId
      @selectedSourceId.set(new Mongo.ObjectID(articleId))

Template.curatorInbox.helpers
  reviewFilter: ->
    Template.instance().reviewFilter

  reviewFilterActive: ->
    Template.instance().reviewFilter.get()

  textFilter: ->
    Template.instance().textFilter

  isReady: ->
    instance = Template.instance()
    instance.ready.get() and not instance.filtering.get()

  selectedSourceId: ->
    Template.instance().selectedSourceId

  query: ->
    Template.instance().query

  searchSettings: ->
    id:"inboxFilter"
    textFilter: Template.instance().textFilter
    classes: 'option'
    placeholder: 'Search inbox'
    toggleable: true

  detailsInView: ->
    Template.instance().currentPaneInView.get() is 'details'

  currentPaneInView: ->
    Template.instance().currentPaneInView

  post: ->
    CuratorSources.findOne publishDate: Template.instance().filter.get()

  posts: ->
    CuratorSources

  settings: ->
    instance = Template.instance()
    fields = instance.curatorInboxFields
    id: "article-curation-table"
    showColumnToggles: false
    fields: fields
    showRowCount: false
    showFilter: false
    rowsPerPage: 20
    #showNavigation: 'never'
    filters: ['curator-inbox-article-filter', 'curator-inbox-review-filter']
    rowClass: (source) ->
      if source._id._str is instance.selectedSourceId?.get()?._str
        'selected'

Template.curatorInbox.events
  'click .curator-filter-reviewed-icon': (event, instance) ->
    reviewFilter = instance.reviewFilter
    if reviewFilter.get()
      reviewFilter.set null
    else
      reviewFilter.set $ne: true
    $(event.currentTarget).tooltip 'destroy'

  'click .curator-filter-calendar-icon': (event, instance) ->
    calendarState = instance.calendarState
    calendarState.set not calendarState.get()
    $(event.currentTarget).tooltip 'destroy'

  'click .back-to-top': (event, instance) ->
    event.preventDefault()
    # animate scrolling back to the top of the scrollable div
    $('.curator-inbox-sources').stop().animate
      scrollTop: 0
    , 500
    $('.back-to-top').fadeOut()

  'click .curator-inbox-table tbody tr
    , keyup .curator-inbox-table tbody tr': (event, instance) ->
    return if not keyboardSelect(event) and event.type is 'keyup'
    selectedSourceId = instance.selectedSourceId
    if selectedSourceId.get()?._str != @_id._str
      selectedSourceId.set(@_id)
      instance.currentPaneInView.set('details')
    $(event.currentTarget).blur()
