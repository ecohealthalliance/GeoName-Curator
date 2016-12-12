clearSearch = (instance) ->
  instance.textFilter.set('')
  instance.$('.search').val('')

Template.searchInput.onCreated ->
  @searching = @data.searching
  @textFilter = @data.textFilter

Template.searchInput.helpers
  searchString: ->
    Template.instance().textFilter.get().$regex

  searchWaiting: ->
    Template.instance().searching.get()

Template.searchInput.events
  'keyup .search, input .search': (event, instance) ->
    if event.type is 'keyup' and event.keyCode is 27
      clearSearch(instance)
    else
      instance.textFilter.set
        $regex: instance.$(event.target).val()
        $options: 'i'

  'click .search-icon:not(.cancel)': (event, instance) ->
    searching = instance.searching
    searching.set not searching.get()
    setTimeout ->
      $('#curator-inbox-article-filter').focus()
    , 200
    $(event.currentTarget).tooltip 'destroy'

  'click .cancel, keyup #curator-inbox-article-filter': (event, instance) ->
    return if event.type is 'keyup' and event.keyCode isnt 27
    clearSearch()
