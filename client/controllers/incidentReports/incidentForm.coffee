createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'

Template.incidentForm.onCreated ->
  { @incidentType,
    @incidentStatus,
    @cumulative,
    @travelRelated } = @data.incidentFormDetails

  @incidentData =
    species: 'Human'
    dateRange:
      type: 'day'

  incident = @data.incident
  if incident
    @incidentData = _.extend(@incidentData, incident)
    if incident.dateRange
      @incidentData.dateRange = incident.dateRange
    @incidentData.value = @incidentData.cases or @incidentData.deaths or @incidentData.specify

    if @incidentData.url
      @incidentData.articleSource = _.findWhere(@data.articles,
        url: @incidentData.url[0]
      )?._id

    if @incidentData.cases
      @incidentType.set('cases')
    else if @incidentData.deaths
      @incidentType.set('deaths')
    else if @incidentData.specify
      @incidentType.set('other')

    @incidentStatus.set incident.status or ''
    @cumulative.set incident.dateRange.cumulative or false
    @travelRelated.set incident.travelRelated or false

Template.incidentForm.onRendered ->
  datePickerOptions = {}
  if @incidentData.dateRange.start and @incidentData.dateRange.end
    datePickerOptions.startDate = @incidentData.dateRange.start
    datePickerOptions.endDate = @incidentData.dateRange.end
  createInlineDateRangePicker(@$('#rangePicker'), datePickerOptions)
  datePickerOptions.singleDatePicker = true
  createInlineDateRangePicker(@$('#singleDatePicker'), datePickerOptions)

Template.incidentForm.helpers
  incidentData: ->
    Template.instance().incidentData

  incidentStatus: ->
    "#{Template.instance().incidentData.status}": true

  incidentType: ->
    "#{Template.instance().incidentType.get()}": true

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

  statusActive: (status) ->
    if status is Template.instance().incidentStatus.get()
      'active'

  typeActive: (type) ->
    if type is Template.instance().incidentType.get()
      'active'

  cumulative: ->
    Template.instance().cumulative.get()

  travelRelated: ->
    Template.instance().travelRelated.get()

  selectedIncidentType: ->
    Template.instance().incidentType.get().slice(0, -1)

keyboardSelect = (event) ->
  keyCode = event.keyCode
  keyCode in [13, 32]

Template.incidentForm.events
  'change input[name=daterangepicker_start]': (event, instance) ->
    instance.$('#singleDatePicker').data('daterangepicker').clickApply()

  'click .status li, keyup .status li': (event, instance) ->
    return if not keyboardSelect(event) and event.type is 'keyup'
    status = instance.incidentStatus
    selectedStatus = instance.$(event.target).data('value')
    if status.get() is selectedStatus
      status.set('')
    else
      status.set(selectedStatus)

  'click .type li, keyup .type li': (event, instance) ->
    return if not keyboardSelect(event) and event.type is 'keyup'
    instance.incidentType.set(instance.$(event.target).data('value'))

  'click .travel-related li, keyup .travel-related li': (event, instance) ->
    return if not keyboardSelect(event) and event.type is 'keyup'
    travelRelated = instance.travelRelated
    travelRelated.set(not travelRelated.get())

  'click .cumulative li, keyup .cumulative li': (event, instance) ->
    return if not keyboardSelect(event) and event.type is 'keyup'
    cumulative = instance.cumulative
    cumulative.set(not cumulative.get())

  'click .select2-selection': (event, instance) ->
    # Remove selected empty item
    firstItem = $('.select2-results__options').children().first()
    if firstItem[0]?.id is ''
      firstItem.remove()
