createInlineDateRangePicker = require '/imports/ui/inlineDateRangePicker.coffee'
validator = require 'bootstrap-validator'
{ keyboardSelect, removeSuggestedProperties, diseaseOptionsFn } = require '/imports/utils'

Template.incidentForm.onCreated ->
  @ignore = new ReactiveVar(false)
  @studySite = new ReactiveVar(false)
  @coordinates = new ReactiveVar(false)
  instanceData = @data
  incident = instanceData.incident
  @suggestedFields = incident?.suggestedFields or new ReactiveVar([])

  @incidentData = {}

  article = instanceData.articles[0]
  if article
    @incidentData.url = article.url

  if incident
    @incidentData = _.extend(@incidentData, incident)
    if @incidentData.ignore
      @ignore.set(true)
    if @incidentData.studySite
      @studySite.set(true)
    if @incidentData.coordinates
      @coordinates.set(true)

Template.incidentForm.onRendered ->
  @$('[data-toggle=tooltip]').tooltip()
  @$('#add-incident').validator()

Template.incidentForm.helpers
  incidentData: ->
    Template.instance().incidentData

  suggestedField: (fieldName)->
    if fieldName in Template.instance().suggestedFields?.get()
      'suggested'

  articleSourceUrl: ->
    Template.instance().data.articles[0]?.url

  ignore: ->
    Template.instance().ignore.get()

  studySite: ->
    Template.instance().studySite.get()

  coordinates: ->
    Template.instance().coordinates.get()

Template.incidentForm.events
  'click .select2-selection': (event, instance) ->
    # Remove selected empty item
    firstItem = $('.select2-results__options').children().first()
    if firstItem[0]?.id is ''
      firstItem.remove()

  'click .ignore label': (event, instance) ->
    instance.ignore.set(not instance.ignore.get())

  'click .study-site label': (event, instance) ->
    instance.studySite.set(not instance.studySite.get())

  'click .coordinates label': (event, instance) ->
    instance.coordinates.set(not instance.coordinates.get())

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
