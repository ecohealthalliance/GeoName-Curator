Template.articleCuration.onCreated ->
  @articleCurationFields = [
    {
      arrayName: '',
      description: 'The article\'s title.',
      displayName: 'Title',
      fieldName: 'url',
      defaultSortDirection: 1
    },
    {
      arrayName: '',
      description: 'Date the article was added.',
      displayName: 'Added',
      fieldName: 'addedDate',
      defaultSortDirection: -1,
      fn: (value) ->
        return moment(value).fromNow()
    }, 
  ]

  @selectedArticle = new ReactiveVar(false)
  @currentPage = new ReactiveVar(Session.get('article-curation-current-page') or 0)
  @rowsPerPage = new ReactiveVar(Session.get('article-curation-rows-per-page') or 20)
  @fieldVisibility = {}
  @sortOrder = {}
  @sortDirection = {}

  for field in @articleCurationFields
    defaultSortOrder = Infinity
    oldSortOrder = Session.get('article-curation-field-sort-order-' + field.fieldName)
    sortOrder = if _.isUndefined(oldSortOrder) then defaultSortOrder else oldSortOrder
    @sortOrder[field.fieldName] = new ReactiveVar(sortOrder)

    defaultSortDirection = field.defaultSortDirection
    oldSortDirection = Session.get('article-curation-field-sort-direction-' + field.fieldName)
    sortDirection = if _.isUndefined(oldSortDirection) then defaultSortDirection else oldSortDirection
    @sortDirection[field.fieldName] = new ReactiveVar(sortDirection)

  @autorun =>
    Session.set 'article-curation-current-page', @currentPage.get()
    Session.set 'article-curation-rows-per-page', @rowsPerPage.get()
    for field in @articleCurationFields
      Session.set 'article-curation-field-sort-order-' + field.fieldName, @sortOrder[field.fieldName].get()
      Session.set 'article-curation-field-sort-direction-' + field.fieldName, @sortDirection[field.fieldName].get()

Template.articleCuration.helpers
  selectedArticle: ->
    return Template.instance().selectedArticle.get()

  settings: ->
    fields = []
    for field in Template.instance().articleCurationFields
      fields.push {
        key: field.fieldName
        label: field.displayName
        sortOrder: Template.instance().sortOrder[field.fieldName]
        sortDirection: Template.instance().sortDirection[field.fieldName]
        sortable: not field.arrayName
        fn: field.fn
      }

    return {
      id: 'article-curation-table'
      showColumnToggles: false
      fields: fields
      currentPage: Template.instance().currentPage
      rowsPerPage: Template.instance().rowsPerPage
      showRowCount: true
      showFilter: false
    }

Template.articleCuration.events
  "click .reactive-table tbody tr": (event, template) ->
    template.selectedArticle.set(@)
  "click .next-page, click .previous-page": ->
    if (window.scrollY > 0 and window.innerHeight < 700)
      $(document.body).animate({scrollTop: 0}, 400)
