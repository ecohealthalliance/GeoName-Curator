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

Template.curatorInbox.helpers
  selectedArticle: ->
    return 0
    # return Template.instance().selectedArticle.get()

  days: ->
    return Template.instance().days

Template.curatorInbox.events
  "click .reactive-table tbody tr": (event, template) ->
    # template.selectedArticle.set(@)
  "click .next-page, click .previous-page": ->
    if (window.scrollY > 0 and window.innerHeight < 700)
      $(document.body).animate({scrollTop: 0}, 400)

Template.curatorInboxSection.onCreated ->
  @curatorInboxFields = [
    {
      key: 'url'
      description: 'The article\'s title.'
      displayName: 'Title'
      sortOrder: 2
      sortDirection: -1
    },
    {
      key: 'publishDate'
      description: 'Date the article was published.'
      displayName: 'Published'
      sortOrder: 1
      sortDirection: -1
      fn: (value) ->
        return moment(value).fromNow()
    }, 
    {
      key: 'addedDate'
      description: 'Date the article was added.'
      displayName: 'Added'
      sortOrder: 0
      sortDirection: -1
      hidden: true
      fn: (value) ->
        return moment(value).format('YYYY-MM-DD')
    }, 
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

Template.curatorInboxSection.helpers
  formattedDate: ->
    return moment(Template.instance().data.date).format('MMMM DD, YYYY')
  settings: ->
    fields = []
    for field in Template.instance().curatorInboxFields
      fields.push {
        key: field.key
        label: field.displayName
        sortOrder: field.sortOrder
        sortDirection: field.sortDirection
        sortable: false
        hidden: field.hidden
        fn: field.fn
      }

    return {
      id: 'article-curation-table'
      showColumnToggles: false
      fields: fields
      showRowCount: false
      showFilter: false
      showNavigation: 'never'
      filters: [Template.instance().filterId]
    }


# moment(article.addedDate).format('MMMM DD, YYYY')