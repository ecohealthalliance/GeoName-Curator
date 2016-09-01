Template.incidentForm.onCreated ->
  @incidentType = new ReactiveVar()
  @incidentData = {
    species: "Human"
  }
  if @data.incident
    @incidentData = _.extend(@incidentData, @data.incident)
    @incidentData.date = moment(@data.incident.date).format('MM/DD/YYYY')
    @incidentData.value = @incidentData.cases or @incidentData.deaths or @incidentData.specify
    if @incidentData.url
      @incidentData.articleSource = _.findWhere(@data.articles, {
        url: @incidentData.url[0]
      })?._id
    if @incidentData.cases
      @incidentType.set("cases")
    else if @incidentData.deaths
      @incidentType.set("deaths")
    else if @incidentData.specify
      @incidentType.set("other")

Template.incidentForm.onRendered ->
  $(document).ready =>
    @$(".datePicker").datetimepicker({
      format: "M/D/YYYY"
      useCurrent: false
    })
    @$(".timePicker").datetimepicker({
      format: "h A"
      useCurrent: false
    })
  ###
  @$(".datePicker").daterangepicker({
      timePicker: true
      timePickerIncrement: 30
      autoUpdateInput: false
      applyClass: "main-btn"
      cancelClass: "secondary-btn"
    })
  ###

Template.incidentForm.helpers
  incidentData: ->
    Template.instance().incidentData
  incidentStatus: ->
    "#{Template.instance().incidentData.status}": true
  incidentType: ->
    "#{Template.instance().incidentType.get()}": true
  articles: ->
    return Template.instance().data.articles
  showCountForm: ->
    type = Template.instance().incidentType.get()
    return type is "cases" or type is "deaths"
  showOtherForm: ->
    return Template.instance().incidentType.get() is "other"
  timezones: ->
    timezones = []
    for tzKey, tzOffset of UTCOffsets
      timezones.push({name: tzKey, offset: tzOffset})
    return timezones

Template.incidentForm.events
  "change select[name='incidentType']": (e, template) ->
    template.incidentType.set($(e.target).val())
