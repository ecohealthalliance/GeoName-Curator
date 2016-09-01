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
      filters: [Template.instance().filterId]
    }

Template.curatorInboxSection.events
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    console.log 'click'
    $details = $("#curator-article-details").html(Blaze.toHTMLWithData(Template.curatorArticleDetails, this))
  "click .curator-inbox-section-head": (event, template) ->
    console.log template.isOpen.curValue
    template.isOpen.set(!template.isOpen.curValue)

Template.curatorArticleDetails.helpers
  formattedAddedDate: ->
    return moment(Template.instance().data.addedDate).format('MMMM DD, YYYY')
  formattedPublishDate: ->
    return moment(Template.instance().data.publishDate).format('MMMM DD, YYYY')
