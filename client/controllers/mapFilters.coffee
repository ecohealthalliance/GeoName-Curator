Template.mapFilters.onCreated ->
  @currentDate = new Date()
  @variables = new ReactiveVar
    incidentDate:
      filter: 'incidentDate'
      state: false
      dateFilter: true
      label: 'Incident Report Date'
      collectionField: '_id'
      values:
        dateCollection: 'incidents'
        searchType: 'on'
        dates: []
  @userSearchText = new ReactiveVar ''
  @filtering = new ReactiveVar false
  @calendarState = new ReactiveVar false

Template.mapFilters.onRendered ->
  instance = @
  @autorun ->
    checkValues = Template.instance().variables.get()
    filters = []
    for name, variable of checkValues
      varQuery = {}
      if instance.filtering.get()
        filterDate = variable.values.dates[0] or new Date()
        if variable.values.dateCollection is 'incidents'
          eventIds = _.uniq(grid.Incidents.find({date: filterDate}, {fields: {userEventId: 1}}).fetch().map((x) -> x.userEventId))
          varQuery[variable.collectionField] = {$in: eventIds}
      filters.push(varQuery)

    userSearchText = Template.instance().userSearchText.get()
    nameQuery = []
    searchWords = userSearchText.split(' ')
    _.each searchWords, -> nameQuery.push {eventName: new RegExp(userSearchText, 'i')}
    filters.push $or: nameQuery

    Template.instance().data.query.set({ $and: filters })

Template.mapFilters.helpers
  variables: ->
    Template.instance().variables

  getVariables: ->
    _.values Template.instance().variables.get()

  getSearchText: ->
    Template.instance().userSearchText.get()

  getCurrentDate: ->
    Template.instance().currentDate

  searchMatch: (matchType, valueType) ->
    matchType is valueType

  getEvents: ->
    Template.instance().data.templateEvents?.get()

  disablePrev: ->
    Template.instance().data.disablePrev?.get()

  disableNext: ->
    Template.instance().data.disableNext?.get()

  filtering: ->
    Template.instance().filtering

  selected: ->
    Template.instance().data.selectedEvents.findOne id: @_id

  calendarState: ->
    Template.instance().calendarState

Template.mapFilters.events
  'click .datePicker': (e, instance) ->
    instance.filtering.set true

  'dp.change .datePicker': (e, instance) ->
    variables = instance.variables.get()
    variable = 'incidentDate'
    dateValues = []
    dateValues.push e.date._d
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

  'click .map-event-list--item': (e, instance) ->
    selectedEvents = instance.data.selectedEvents
    id = @_id
    if selectedEvents.findOne(id: id)
      selectedEvents.remove id: id
    else
      selectedEvents.insert
        id: id
        rgbColor: @rgbColor
        incidents: @incidents
        selected: true

  'click .toggle-calendar-state': (e, instance) ->
    calendarState = instance.calendarState
    calendarState.set not calendarState.get()


Template.dateSelector.onRendered ->
  instance = Template.instance()
  instance.$(".datePicker").datetimepicker
    format: "M/D/YYYY"
    widgetPositioning: {vertical: "bottom"}
    inline: true
    defaultDate: false

setSearchType = (instance, type) ->
  variables = instance.data.variables
  _variables = variables.get()
  _variables.incidentDate.values.searchType = type
  variables.set _variables

Template.dateSelector.helpers
  calendarState: ->
    Template.instance().data.calendarState.get()
  searchTypeSelected: (type) ->
    Template.instance().data.variables.get().incidentDate.values.searchType is type

Template.dateSelector.events
  'click .before': (event, instance) ->
    setSearchType(instance, 'before')
  'click .after': (event, instance) ->
    setSearchType(instance, 'after')
