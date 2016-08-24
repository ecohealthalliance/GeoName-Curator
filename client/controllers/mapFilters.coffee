Template.dateSelector.rendered = ->
  instance = Template.instance()
  instance.$(".datePicker").datetimepicker
    format: "M/D/YYYY"
    defaultDate: instance.data.currentDate
    widgetPositioning: {vertical: "bottom"}

Template.mapFilters.created = ->
  @currentDate = new Date()
  @variables = new ReactiveVar {
    "incidentDate":
      filter: "incidentDate"
      state: false
      dateFilter: true
      label: "Incident Report Date"
      collectionField: "_id"
      values:
        dateCollection: "counts"
        searchType: "on"
        dates: []
  }
  @userSearchText = new ReactiveVar ''

Template.mapFilters.rendered = ->
  @autorun ->
    checkValues = Template.instance().variables.get()
    filters = []

    for name, variable of checkValues
      if variable.state
        varQuery = {}
        if variable.dateFilter
          filterDate = variable.values.dates[0]
          if variable.values.searchType is "between"
            filterDate2 = variable.values.dates[1]
          mongoProjection = switch variable.values.searchType
            when "after" then {date: {$gt: filterDate}}
            when "before" then {date: {$lt: filterDate}}
            when "between" then {date: {$gte: filterDate, $lte: filterDate2}}
            else {date: filterDate}
          if variable.values.dateCollection is "counts"
            eventIds = _.uniq(grid.Counts.find(mongoProjection, {fields: {userEventId: 1}}).fetch().map((x) -> x.userEventId))
            varQuery[variable.collectionField] = {$in: eventIds}
        filters.push(varQuery)

    userSearchText = Template.instance().userSearchText.get()
    nameQuery = []
    searchWords = userSearchText.split(' ')
    _.each searchWords, -> nameQuery.push {eventName: new RegExp(userSearchText, 'i')}
    filters.push({$or: nameQuery})

    Template.instance().data.query.set({ $and: filters })

Template.mapFilters.helpers
  getVariables: ->
    _.values Template.instance().variables.get()

  getSearchText: ->
    Template.instance().userSearchText.get()

  getCurrentDate: ->
    return Template.instance().currentDate

  searchMatch: (matchType, valueType) ->
    return matchType is valueType

Template.mapFilters.events
  'click .filter': (e, instance) ->
    instance.$('.filter').toggleClass('open')
    instance.$('.filters-wrap').toggleClass('hidden')

  'click input[type=checkbox]': (e, instance) ->
    variables = instance.variables.get()
    variable = $(e.target).parents(".filter-block").data("filter")
    variables[variable].state = e.target.checked
    instance.variables.set(variables)

  "change input[type=radio]": (e, instance) ->
    variables = instance.variables.get()
    $target = $(e.target)
    variable = $target.parents(".filter-block").data("filter")
    type = $target.val()
    if type is "between"
      variables[variable].values.dates.push(instance.currentDate)
    else if variables[variable].values.dates.length > 1
      variables[variable].values.dates.pop()
    variables[variable].values.searchType = type
    instance.variables.set(variables)
  
  "dp.change input.datePicker": (e, instance) ->
    variables = instance.variables.get()
    $parentBlock = $(e.target).parents(".filter-block")
    variable = $parentBlock.data("filter")
    dateValues = []
    $parentBlock.find("input.datePicker").each( ->
      dateValues.push(new Date($(this).val()))
    )
    variables[variable].values.dates = dateValues
    instance.variables.set(variables)

  'input .map-search': _.debounce (e, templateInstance) ->
    e.preventDefault()
    text = $(e.target).val()
    templateInstance.userSearchText.set(text)

  'click .clear-search': (e, instance) ->
    instance.$('.map-search').val('')
    Template.instance().userSearchText.set('')

  'click .mobile-control': (e, instance) ->
    instance.$('.map-search-wrap').toggleClass('open')
