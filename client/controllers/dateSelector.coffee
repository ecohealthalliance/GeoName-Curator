createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker'
{ setVariables,
  clearDateRange }          = require '/imports/ui/setRange'

Template.dateSelector.onCreated ->
  @additionalOptions = new ReactiveVar false

Template.dateSelector.onRendered ->
  date = new Date()
  @picker = createInlineDateRangePicker @$('.date-picker-container'),
    autoUpdateInput: false
    locale: cancelLabel: "Clear"
    autoApply: true
    startDate: @data.dateVariables.get().dates[0] or date
    endDate: @data.dateVariables.get().dates[1] or date

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

  dateFiltering: ->
    Template.instance().data.dateVariables.get().dates.length



Template.dateSelector.events
  'apply.daterangepicker .date-picker-container': (event, instance) ->
    dateFormat = "M/D/YYYY"
    $target = $(event.target)
    picker = instance.picker
    start = picker.startDate
    end = picker.endDate

    $target.val(start.format(dateFormat) + " - " + end.format(dateFormat))
    setVariables instance, 'on', [start.toDate(), end.toDate()]

  'click .additional-date-options': (event, instance) ->
    instance.additionalOptions.set true

  'dp.change .date-picker': (event, instance) ->
    clearDateRange instance.picker
    selectedDate = event.date.toDate()
    type = instance.$(event.target).data('type')
    dates = if type is 'after' then [null, selectedDate] else [selectedDate, null]
    setVariables instance, type, dates

  'click .clear-date': (event, instance) ->
    setVariables instance, 'on', []
    instance.$('input').val('')

  'click .clear-all-date-filters': (event, instance) ->
    clearDateRange instance.picker
    setVariables instance, 'on', []
