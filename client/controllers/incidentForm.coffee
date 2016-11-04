createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'

Template.incidentForm.onCreated ->
  @incidentType = new ReactiveVar()
  @incidentData = {
    species: "Human"
    dateRange: {
      type: "day"
    }
  }

  if @data.incident
    @incidentData = _.extend(@incidentData, @data.incident)
    if @data.incident.dateRange
      @incidentData.dateRange = @data.incident.dateRange
    @incidentData.value = @incidentData.cases or @incidentData.deaths or @incidentData.specify
    if @incidentData.url
      @incidentData.articleSource = _.findWhere(@data.articles, {
        url: @incidentData.url[0]
      })?._id
    if @incidentData.cases
      @incidentType.set('cases')
    else if @incidentData.deaths
      @incidentType.set('deaths')
    else if @incidentData.specify
      @incidentType.set('other')

Template.incidentForm.onRendered ->
  $(document).ready =>
    datePickerOptions = {}
    if @incidentData.dateRange.start and @incidentData.dateRange.end
      datePickerOptions.startDate = @incidentData.dateRange.start
      datePickerOptions.endDate = @incidentData.dateRange.end
    createInlineDateRangePicker(@.$('#rangePicker'), datePickerOptions)
    datePickerOptions.singleDatePicker = true
    createInlineDateRangePicker(@.$('#singleDatePicker'), datePickerOptions)

Template.incidentForm.helpers
  incidentData: ->
    Template.instance().incidentData

  incidentStatus: ->
    '#{Template.instance().incidentData.status}': true

  incidentType: ->
    '#{Template.instance().incidentType.get()}': true

  articles: ->
    Template.instance().data.articles

  showCountForm: ->
    type = Template.instance().incidentType.get()
    type is 'cases' or type is 'deaths'

  showOtherForm: ->
    Template.instance().incidentType.get() is 'other'

  dayTabClass: ->
    if Template.instance().incidentData.dateRange.type is 'day'
      'active'

  rangeTabClass: ->
    if Template.instance().incidentData.dateRange.type is 'precise'
      'active'

Template.incidentForm.events
  'change select[name=incidentType]': (e, template) ->
    template.incidentType.set($(e.target).val())
  'change input[name=daterangepicker_start]': (e, template) ->
    $('#singleDatePicker').data('daterangepicker').clickApply()
