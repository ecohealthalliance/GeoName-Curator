createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker'
{ setVariables,
  clearDateRange }          = require '/imports/ui/setRange'

Template.dateSelector.onRendered ->
  date = new Date()
  @picker = createInlineDateRangePicker @$('.date-picker-container'),
    autoUpdateInput: false
    locale: cancelLabel: "Clear"
    autoApply: true
    startDate: @data.dateVariables.get().dates[0] or date
    endDate: @data.dateVariables.get().dates[1] or date

Template.dateSelector.helpers
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

  'click .clear-all-date-filters': (event, instance) ->
    clearDateRange instance.picker
    setVariables instance, 'on', []
