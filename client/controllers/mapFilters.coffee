Template.mapFilters.created = ->
  filterVariables = ["countDate"]
  @variables = new ReactiveVar {
    "countDate": {
      class: "countDate"
      state: false
      showDateAttributes: true
      value: "Incident Report Date"
    }
  }
  @userSearchText = new ReactiveVar ''

Template.mapFilters.rendered = ->
  @autorun ->
    checkValues = Template.instance().variables.get()
    filters =[]
    ###
      _.chain(checkValues)
        .map((variable) ->
          checkedValues = []
          checkedValues = (name for name, valueInfo of variable.values when valueInfo.state)
          if checkedValues.length
            _.map checkedValues, (value) ->
              varQuery = {}
              if variable.strictSearch
                varQuery[variable.spreadsheetName] = new RegExp('^'+value+'$', 'i')
              else
                varQuery[variable.spreadsheetName] = new RegExp(value, 'i')
              varQuery
          else
            varQuery = {}
            varQuery[variable.variable] = ''
            [varQuery]
        ).map((variable) -> {$or: variable})
        .value()
    ###
    userSearchText = Template.instance().userSearchText.get()
    nameQuery = []
    searchWords = userSearchText.split(' ')
    _.each searchWords, -> nameQuery.push {eventName: new RegExp(userSearchText, 'i')}
    filters.push({$or: nameQuery})

    Template.instance().data.query.set({ $and: filters })

  popoverOptions =
    trigger: 'hover'
    placement: 'left'
    animation: false
    container: 'body'
    delay:
      show: 500
      hide: 100
    template: """<div class="popover map-filter-popover" role="tooltip"><div class="arrow"></div><div class="popover-content"></div></div>"""
  $("[data-toggle='popover']").popover(popoverOptions)

getCheckboxStates = ->
  (valueInfo.state for name, valueInfo of @checkBoxes.get()[@variable].values)

checkAll = (state) ->
  variables = Template.instance().variables.get()
  for value of variables[@variable].values
    variables[@variable]['values'][value].state = state
  Template.instance().variables.set(variables)

Template.mapFilters.helpers
  getCheckboxList: ->
    Template.instance().variables

  getVariables: ->
    _.values Template.instance().variables.get()

  getValues: ->
    values = []
    for name, valueInfo of @values
      values.push
        name: name
        state: valueInfo.state
        description: valueInfo.description
    values

  getSearchText: ->
    Template.instance().userSearchText.get()

Template.mapFilters.events
  'click .filter': (e, instance) ->
    $wrap = instance.$('.filters-wrap')
    initCalendar = $wrap.hasClass("hidden")
    if not initCalendar
      instance.$(".datePicker").data("DateTimePicker").destroy()
    instance.$('.filter').toggleClass('open')
    $wrap.toggleClass('hidden')
    if initCalendar
      instance.$(".datePicker").datetimepicker
        format: "M/D/YYYY"
        defaultDate: new Date()
        widgetPositioning: {vertical: "bottom"}

  'click input[type=checkbox]': (e) ->
    variables = Template.instance().variables.get()
    target = $(e.target)
    variable = target[0].className
    state = target[0].checked
    date
    variables[variable].state = state
    Template.instance().variables.set(variables)

  'input .map-search': _.debounce (e, templateInstance) ->
    e.preventDefault()
    text = $(e.target).val()
    templateInstance.userSearchText.set(text)

  'click .clear-search': (e, instance) ->
    instance.$('.map-search').val('')
    Template.instance().userSearchText.set('')

  'click .check': (e) ->
    if $(e.target).hasClass('check-all')
      checkAll.call(this,false)
    else
      checkAll.call(this, true)

  'click .mobile-control': (e, instance) ->
    instance.$('.map-search-wrap').toggleClass('open')
