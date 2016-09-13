Template.curatorInbox.onCreated ->
  @selectedArticle = false
  @allArticles = grid.Articles.find({}, {sort: {addedDate: -1}}).fetch()

  @days = []
  recordedDates = {}
  for article in @allArticles
    date = new Date(article.addedDate.getFullYear(), article.addedDate.getMonth(), article.addedDate.getDate())
    recordedDates[date.getTime()] = date

  for key of recordedDates
    @days.push recordedDates[key]
  @days.sort

  @textFilter = new ReactiveTable.Filter('curator-inbox-article-filter', ['url'])

Template.curatorInbox.helpers
  days: ->
    return Template.instance().days

Template.curatorInbox.events
  "keyup #curator-inbox-article-filter, input #curator-inbox-article-filter": (event, template) ->
    template.textFilter.set($(event.target).val())

Template.curatorInboxSection.onCreated ->
  @curatorInboxFields = [
    {
      key: 'curated'
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
      key: 'url'
      description: 'The article\'s title.'
      label: 'Title'
      sortDirection: -1
    },
    {
      key: 'publishDate'
      description: 'Date the article was published.'
      label: 'Published'
      sortDirection: -1
      fn: (value) ->
        return moment(value).fromNow()
    }, 
    {
      key: 'addedDate'
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
  @filter = new ReactiveTable.Filter(@filterId, ['addedDate'])
  @filter.set({
    $gte: today
    $lt: tomorrow
  })

  @isOpen = new ReactiveVar(@data.index < 3)

Template.curatorInboxSection.helpers
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
      showNavigation: 'never'
      filters: [Template.instance().filterId, 'curator-inbox-article-filter']
    }

Template.curatorInboxSection.events
  "click .curator-inbox-table tbody tr": (event, template) ->
    $(".details-open").removeClass("details-open")
    $parentRow = $(event.target).closest("tr")
    $parentRow.addClass("details-open")
    $("#curator-article-details").html("")
    details = document.getElementById("curator-article-details")
    Blaze.renderWithData(Template.curatorArticleDetails, this, details)
    if (window.scrollY > 0 and window.innerHeight < 700)
      $(document.body).animate({scrollTop: 0}, 400)
  "click .curator-inbox-section-head": (event, template) ->
    template.isOpen.set(!template.isOpen.curValue)

Template.curatorArticleDetails.helpers
  title: ->
    return Template.instance().data.url
  isCurated: ->
    if Template.instance().data.curated
      return 'curated'
  formattedAddedDate: ->
    return moment(Template.instance().data.addedDate).format('MMMM DD, YYYY')
  formattedPublishDate: ->
    return moment(Template.instance().data.publishDate).format('MMMM DD, YYYY')