createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'

createInboxSections = () ->
  sections = []
  recordedDates = {}
  allPosts = PromedPosts.find({}, {sort: {sourceDate: -1}}).fetch()
  if allPosts.length == 0
    return []
  for post in allPosts
    date = new Date(post.sourceDate.getFullYear(), post.sourceDate.getMonth(), post.sourceDate.getDate())
    recordedDates[date.getTime()] = date
  for key of recordedDates
    sections.push recordedDates[key]
  sections.sort
  return sections

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
  @days = []
  @textFilter = new ReactiveTable.Filter('curator-inbox-article-filter', ['url'])
  @reviewFilter = new ReactiveTable.Filter('curator-inbox-review-filter', ['reviewed'])

  self = @

  @sub = Meteor.subscribe "promedPosts", () ->
    self.days = createInboxSections()
    self.ready.set(true)

Template.curatorInbox.onRendered ->
  $(document).ready =>
    createNewCalendar()

Template.curatorInbox.onDestroyed ->
  @sub.stop()

Template.curatorInbox.helpers
  days: ->
    return Template.instance().days

  calendarState: ->
    return Template.instance().calendarState.get()

  reviewedState: ->
    if Template.instance().reviewFilter.get()
      return false
    return true

  isReady: ->
    return Template.instance().ready.get()

  isLoading: ->
    return !Template.instance().ready.get()

Template.curatorInbox.events
  "keyup #curator-inbox-article-filter, input #curator-inbox-article-filter": (event, template) ->
    template.textFilter.set($(event.target).val())

  "click .curator-refresh-icon": (event, template) ->
    template.refresh()

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
    template.sub.stop()

    range = null
    startDate = $('#date-picker').data('daterangepicker').startDate
    endDate = $('#date-picker').data('daterangepicker').endDate

    if startDate and !endDate
      endDate = startDate

    if startDate and endDate
      range = {
        startDate: startDate.format(),
        endDate: endDate.format()
      }

    template.sub = Meteor.subscribe "promedPosts", 2000, range, () ->
      template.days = createInboxSections()
      template.ready.set(true)

  "click #calendar-btn-reset": (event, template) ->
    template.calendarState.set(false)
    template.ready.set(false)
    template.sub.stop()

    createNewCalendar()

    template.sub = Meteor.subscribe "promedPosts", 100, null, () ->
      template.days = createInboxSections()
      template.ready.set(true)

  "click #calendar-btn-cancel": (event, template) ->
    template.calendarState.set(false)

Template.curatorInboxSection.onCreated ->
  @curatorInboxFields = [
    {
      key: 'reviewed'
      description: 'Article has been curated'
      label: ''
      cellClass: (value) ->
        if value
          return 'curator-inbox-curated-row'
      sortDirection: -1
      fn: (value) ->
        return ''
    },
    {
      key: 'source'
      description: 'The post\'s source metadata.'
      label: 'Title'
      sortDirection: -1
      fn: (value, obj) ->
        
        if value and value.name
          return lodash.truncate(value.name, {length: 50})
        else if obj.communicatedBy
          return lodash.truncate(obj.communicatedBy, {length: 50})
        return 'No source name.'
    },
    {
      key: 'promedDate'
      description: 'Date the article was published.'
      label: 'Published'
      sortDirection: -1
      fn: (value) ->
        return moment(value).fromNow()
    }, 
    {
      key: 'sourceDate'
      description: 'Date the article was added.'
      label: 'Added'
      sortOrder: 0
      sortDirection: -1
      hidden: true
      fn: (value) ->
        return moment(value).format('YYYY-MM-DD')
    },
    {
      key: "expand"
      label: ""
      cellClass: "details-row"
    }
  ]

  today = Template.instance().data.date
  tomorrow = new Date(today)
  tomorrow.setDate(tomorrow.getDate() + 1)

  @filterId = 'inbox-date-filter-'+today.getTime()
  @filter = new ReactiveTable.Filter(@filterId, ['sourceDate'])
  @filter.set({
    $gte: today
    $lt: tomorrow
  })

  @isOpen = new ReactiveVar(@data.index < 3)

Template.curatorInboxSection.helpers
  posts: ->
    return PromedPosts
  isOpen: ->
    return Template.instance().isOpen.get()
  formattedDate: ->
    return moment(Template.instance().data.date).format('MMMM DD, YYYY')
  settings: ->
    fields = []
    for field in Template.instance().curatorInboxFields
      fields.push {
        key: field.key
        label: field.label
        sortOrder: field.sortOrder || 99
        sortDirection: field.sortDirection || 99
        sortable: false
        hidden: field.hidden
        cellClass: field.cellClass
        fn: field.fn
      }

    return {
      id: 'article-curation-table'
      showColumnToggles: false
      fields: fields
      showRowCount: false
      showFilter: false
      rowsPerPage: 200
      showNavigation: 'never'
      filters: [Template.instance().filterId, 'curator-inbox-article-filter', 'curator-inbox-review-filter']
    }

Template.curatorInboxSection.events
  "click .curator-inbox-table tbody tr": (event, template) ->
    $(".details-open").removeClass("details-open")
    $parentRow = $(event.target).closest("tr")
    $parentRow.addClass("details-open")
    $("#curator-article-details").html("")
    details = document.getElementById("curator-article-details")
    Blaze.renderWithData(Template.curatorSourceDetails, {_id: this._id}, details)
    if (window.scrollY > 0 and window.innerHeight < 700)
      $(document.body).animate({scrollTop: 0}, 400)
  "click .curator-inbox-section-head": (event, template) ->
    template.isOpen.set(!template.isOpen.curValue)
