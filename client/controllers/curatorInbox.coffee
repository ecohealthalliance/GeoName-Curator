CuratorSources = require '/imports/collections/curatorSources.coffee'
createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'

createNewCalendar = () ->
  createInlineDateRangePicker($("#date-picker"), {maxDate: new Date(), useDefaultDate: true})
  calendar = $('#date-picker').data('daterangepicker')
  currentMonth = moment({ month: moment().month() })
  lastMonth = moment({ month: moment().subtract(1, 'months').month() })
  calendar.rightCalendar.month = currentMonth
  calendar.leftCalendar.month = lastMonth
  calendar.updateCalendars()

Template.curatorInbox.onCreated ->
  @calendarState = new ReactiveVar false
  @ready = new ReactiveVar false
  @selectedArticle = false
  @dateRange = new ReactiveVar
    startDate: moment().subtract(1, 'weeks').toDate()
    endDate: new Date()
  @textFilter = new ReactiveTable.Filter('curator-inbox-article-filter', ['url'])
  @reviewFilter = new ReactiveTable.Filter('curator-inbox-review-filter', ['reviewed'])
  @reviewFilter.set({$ne: true})

  @autorun =>
    Meteor.call 'fetchPromedPosts', 100, @dateRange.get(), (err) ->
      if err
        console.log(err)
        return toastr.error(err.reason)
    @subscribe "curatorSources", @dateRange.get(), () =>
      @ready.set(true)

Template.curatorInbox.onRendered ->
  $(document).ready =>
    createNewCalendar()

Template.curatorInbox.helpers
  days: ->
    {startDate, endDate} = Template.instance().dateRange.get()
    days = _.range(moment(endDate).diff(startDate, 'days') + 1).map (dayOffset)->
      moment(startDate).add(dayOffset, 'days').set(
        hours:0
        minutes:0
        seconds:0
      ).toDate()
    days.reverse()

  calendarState: ->
    Template.instance().calendarState.get()

  reviewFilter: ->
    Template.instance().reviewFilter

  reviewFilterActive: ->
    Template.instance().reviewFilter.get()

  isReady: ->
    Template.instance().ready.get()

  isLoading: ->
    !Template.instance().ready.get()

Template.curatorInbox.events
  "keyup #curator-inbox-article-filter, input #curator-inbox-article-filter": (event, template) ->
    template.textFilter.set($(event.target).val())

  "click .curator-filter-calendar-icon": (event, template) ->
    calendarState = template.calendarState
    calendarState.set not calendarState.get()

  "click .curator-filter-calendar-icon": (event, template) ->
    calendarState = template.calendarState
    calendarState.set not calendarState.get()

  "click .curator-filter-reviewed-icon": (event, template) ->
    if template.reviewFilter.get()
      template.reviewFilter.set(null)
    else
      template.reviewFilter.set({$ne: true})

  "click #calendar-btn-apply": (event, template) ->
    template.calendarState.set(false)
    template.ready.set(false)

    range = null
    startDate = $('#date-picker').data('daterangepicker').startDate
    endDate = $('#date-picker').data('daterangepicker').endDate

    if startDate and !endDate
      endDate = startDate

    if startDate and endDate
      range = {
        startDate: startDate.toDate()
        endDate: endDate.toDate()
      }
      template.dateRange.set range

  "click #calendar-btn-reset": (event, template) ->
    template.calendarState.set(false)
    template.ready.set(false)

    createNewCalendar()

    template.dateRange.set
      startDate: moment().subtract(1, 'weeks').toDate()
      endDate: new Date()

  "click #calendar-btn-cancel": (event, template) ->
    template.calendarState.set(false)

Template.curatorInboxSection.onRendered ->
  # select the first item in the inbox
  if $(".details-open").length == 0
    $(".curator-inbox-table tbody tr:first").click()

Template.curatorInboxSection.onCreated ->
  @curatorInboxFields = [
    {
      key: 'reviewed'
      description: 'Article has been curated'
      label: ''
      cellClass: (value) ->
        if value
          'curator-inbox-curated-row'
      sortDirection: -1
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
      key: 'publishDate'
      description: 'Date the article was published.'
      label: 'Published'
      sortOrder: 0
      sortDirection: -1
      sortFn: (value, ctx)->
        value
      fn: (value) ->
        if moment(value).diff(new Date(), 'days') > -7
          moment(value).fromNow()
        else
          moment(value).format('YYYY-MM-DD')
    },
    {
      key: 'addedDate'
      description: 'Date the article was added.'
      label: 'Added'
      sortDirection: -1
      hidden: true
      fn: (value) ->
        moment(value).format('YYYY-MM-DD')
    },
    {
      key: "expand"
      label: ""
      cellClass: "details-row"
    }
  ]

  sectionDate = Template.instance().data.date
  @filterId = 'inbox-date-filter-'+sectionDate.getTime()
  @filter = new ReactiveTable.Filter(@filterId, ['publishDate'])
  @filter.set(
    $gte: sectionDate
    $lt: moment(sectionDate).add(1, 'day').toDate()
  )

  @isOpen = new ReactiveVar(@data.index < 5)

Template.curatorInboxSection.helpers
  post: ->
    CuratorSources.findOne publishDate: Template.instance().filter.get()

  posts: ->
    CuratorSources

  count: ->
    sectionDate = Template.instance().data.date
    filterArray = [
                {  "publishDate": {
                    $gte: sectionDate
                    $lt: moment(sectionDate).add(1, 'day').toDate()
                  }
                }
    ]
    reviewFilter = Template.instance().data.reviewFilter.get()
    # adjust counts based on whether we are showing accepted sources or not
    if reviewFilter
      filterArray.push _.object(Template.instance().data.reviewFilter.fields.map((field)->
        [field, reviewFilter]
      ))
    filter = $and: filterArray
    CuratorSources.find(filter).fetch().length

  isOpen: ->
    Template.instance().isOpen.get()

  formattedDate: ->
    moment(Template.instance().data.date).format('MMMM DD, YYYY')

  settings: ->
    fields = Template.instance().curatorInboxFields

    id: 'article-curation-table'
    showColumnToggles: false
    fields: fields
    showRowCount: false
    showFilter: false
    rowsPerPage: 200
    showNavigation: 'never'
    filters: [Template.instance().filterId, 'curator-inbox-article-filter', 'curator-inbox-review-filter']

Template.curatorInboxSection.events
  'click .curator-inbox-table tbody tr': (event, template) ->
    $('.details-open').removeClass('details-open')
    $parentRow = $(event.target).closest('tr')
    $parentRow.addClass('details-open')
    $('.curator-source-details').html('')
    details = $('.curator-source-details')[0]
    Blaze.renderWithData(Template.curatorSourceDetails, @, details)
    if (window.scrollY > 0 and window.innerHeight < 700)
      $(document.body).animate({scrollTop: 0}, 400)

  'click .curator-inbox-section-head': (event, template) ->
    template.isOpen.set(!template.isOpen.curValue)

Template.curatorSourceDetails.onCreated ->
  @contentIsOpen = new ReactiveVar(false)
  @reviewed = new ReactiveVar @data.reviewed or false

Template.curatorSourceDetails.onRendered ->
  @$('.toggle-source-content').tooltip()
  
Template.curatorSourceDetails.helpers
  post: ->
    return CuratorSources.findOne({_id: @_id})

  contentIsOpen: ->
    Template.instance().contentIsOpen.get()

  formattedScrapeDate: ->
    moment(Template.instance().data.sourceDate).format('MMMM DD, YYYY')

  formattedPromedDate: ->
    moment(Template.instance().data.promedDate).format('MMMM DD, YYYY')

  isReviewed: ->
    Template.instance().reviewed.get()

Template.curatorSourceDetails.events
  "click .toggle-reviewed": (event, template) ->
    reviewed = template.reviewed
    reviewed.set not reviewed.get()
    Meteor.call('curateSource', template.data._id, reviewed.get())

  'click .toggle-source-content': (event, template) ->
    open = template.contentIsOpen
    open.set not open.get()
