Template.incidentForm.onCreated ->
  @incidentType = new ReactiveVar()
  @incidentData = {}
  if @data.incident
    @incidentData = @data.incident
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
  @$(".datePicker").datetimepicker(
    format: "M/D/YYYY",
    useCurrent: false
  )

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

Template.incidentForm.events
  "change select[name='incidentType']": (e, template) ->
    template.incidentType.set($(e.target).val())
