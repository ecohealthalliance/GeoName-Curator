createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'

Template.mapFilters.onCreated ->
  @dateVariables = new ReactiveVar
    searchType: 'on'
    dates: []
  @userSearchText = new ReactiveVar ''
  @filtering = new ReactiveVar false
  @calendarState = new ReactiveVar false

Template.mapFilters.onRendered ->
  instance = @
  @autorun ->
    checkValues = Template.instance().dateVariables.get()
    filters = []
    if instance.filtering.get()
      varQuery = {}
      if checkValues.dates.length
        startFilterDate = checkValues.dates[0]
        endFilterDate = checkValues.dates[1]
        switch checkValues.searchType
          when 'after' then dateProjection = {'dateRange.end': {$gt: endFilterDate}}
          when 'before' then dateProjection = {
            $or: [
              {
                'dateRange.cumulative': false
                'dateRange.start': {$lt: startFilterDate}
              },
              {
                'dateRange.cumulative': true
              }
            ]
          }
          else dateProjection = {
            $or: [
              {
                'dateRange.cumulative': false
                'dateRange.start': {$lte: endFilterDate}
                'dateRange.end': {$gte: startFilterDate}
              },
              {
                'dateRange.cumulative': true
                'dateRange.end': {$gte: startFilterDate}
              }
            ]
          }
        eventIds = _.uniq(grid.Incidents.find(dateProjection, {fields: {userEventId: 1}}).fetch().map((x) -> x.userEventId))
        varQuery._id = {$in: eventIds}
        filters.push(varQuery)

    userSearchText = Template.instance().userSearchText.get()
    nameQuery = []
    searchWords = userSearchText.split(' ')
    _.each searchWords, -> nameQuery.push {eventName: new RegExp(userSearchText, 'i')}
    filters.push $or: nameQuery

    Template.instance().data.query.set({ $and: filters })

Template.mapFilters.helpers
  dateVariables: ->
    Template.instance().dateVariables

  getSearchText: ->
    Template.instance().userSearchText.get()

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

  eventsAreSelected: ->
    Template.instance().data.selectedEvents.findOne()

  calendarState: ->
    Template.instance().calendarState.get()

Template.mapFilters.events
  'cancel.daterangepicker': (e, instance) ->
    $(e.target).val("")
    instance.filtering.set(false)
    variables = instance.dateVariables.get()
    variables.searchType = "on"
    instance.dateVariables.set(variables)

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

  'click .deselect-all': (e, instance) ->
    instance.data.selectedEvents.remove({})

Template.dateSelector.onCreated ->
  @additionalOptions = new ReactiveVar false

Template.dateSelector.onRendered ->
  createInlineDateRangePicker @$('.date-picker-container'),
    autoUpdateInput: false
    locale: cancelLabel: "Clear"
    autoApply: true

  instance = @
  @autorun ->
    instance.additionalOptions.get()
    Meteor.defer ->
      $('.after-date-picker').datetimepicker()
      $('.before-date-picker').datetimepicker()

Template.dateSelector.helpers
  searchTypeSelected: (type) ->
    Template.instance().data.dateVariables.get().searchType is type

  additionalOptions: ->
    instance = Template.instance()
    instance.additionalOptions.get() or instance.data.dateVariables.get().searchType in ['before', 'after']

  searchingBeforeAfter: ->
    Template.instance().data.dateVariables.get().searchType in ['before', 'after']

Template.dateSelector.events
  'apply.daterangepicker .date-picker-container': (event, instance) ->
    dateFormat = "M/D/YYYY"
    $target = $(event.target)
    picker = $target.data("daterangepicker")
    variables = instance.data.dateVariables
    _variables = variables.get()
    start = picker.startDate
    end = picker.endDate
    $target.val(start.format(dateFormat) + " - " + end.format(dateFormat))
    _variables.dates = [start.toDate(), end.toDate()]
    variables.set _variables
    instance.data.filtering.set true
    picker.show()

  'click .additional-date-options': (event, instance) ->
    instance.additionalOptions.set true

  'dp.change .date-picker': (event, instance) ->
    selectedDate = event.date.toDate()
    variables = instance.data.dateVariables
    _variables = variables.get()
    type = instance.$(event.target).data 'type'
    _variables.searchType = type
    _variables.dates =
      if type is 'after' then [null, selectedDate] else [selectedDate, null]
    variables.set _variables
    instance.data.filtering.set true
  'click .clear-date': (event, instance) ->
    variables = instance.data.dateVariables
    _variables = variables.get()
    _variables.searchType = 'on'
    _variables.dates = []
    variables.set _variables
    instance.$('input').val('')
