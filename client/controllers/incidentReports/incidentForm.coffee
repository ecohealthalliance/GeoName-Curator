createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'
validator = require 'bootstrap-validator'
{ keyboardSelect, removeSuggestedProperties, diseaseOptionsFn } = require '/imports/utils'

_selectInput = (event, instance, prop, isCheckbox) ->
  return if not keyboardSelect(event) and event.type is 'keyup'
  if isCheckbox is 'checkbox'
    prop = instance[prop]
    prop.set(not prop.get())
  else
    clickedInput = instance.$(event.target).attr('for')
    state = instance[prop]
    if state.get() is clickedInput
      state.set(null)
    else
      state.set(clickedInput)

Template.incidentForm.onCreated ->
  instanceData = @data
  incident = instanceData.incident
  @suggestedFields = incident?.suggestedFields or new ReactiveVar([])

  @incidentData = {}

  article = instanceData.articles[0]
  if article
    @incidentData.url = article.url

  if incident
    @incidentData = _.extend(@incidentData, incident)
    if incident.dateRange
      @incidentData.dateRange = incident.dateRange


Template.incidentForm.onRendered ->
  @$('[data-toggle=tooltip]').tooltip()
  @$('#add-incident').validator()

Template.incidentForm.helpers
  incidentData: ->
    Template.instance().incidentData

  articles: ->
    Template.instance().data.articles

  selectedIncidentType: ->
    switch Template.instance().incidentType.get()
      when 'cases' then 'Case'
      when 'deaths' then 'Death'

  suggestedField: (fieldName)->
    if fieldName in Template.instance().suggestedFields?.get()
      'suggested'

  articleSourceUrl: ->
    Template.instance().data.articles[0]?.url

Template.incidentForm.events
  'click .select2-selection': (event, instance) ->
    # Remove selected empty item
    firstItem = $('.select2-results__options').children().first()
    if firstItem[0]?.id is ''
      firstItem.remove()

  'mouseup .select2-selection': (event, instance) ->
    removeSuggestedProperties(instance, ['locations'])

  'submit form': (event, instance) ->
    prevented = event.isDefaultPrevented()
    instance.data.valid.set(not prevented)
    if prevented
      # Toggle focus on location input so 'has-error' class is applied
      if not instance.$('.select2-selection__choice').length
        instance.$('.select2-search__field').blur()
        instance.$('.has-error:first-child').focus()
    event.preventDefault()
