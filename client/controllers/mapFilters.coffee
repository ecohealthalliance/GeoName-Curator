createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker'
{ setVariables }            = require '/imports/ui/setRange'

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
    setVariables instance, 'on', []

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
