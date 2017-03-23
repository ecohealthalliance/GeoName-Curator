{ annotateContent } = require('/imports/ui/annotation')

POPUP_DELAY = 100

_setSelectingState = (instance, state) ->
  instance.selecting.set(state)

Template.annotatedContent.onCreated ->
  @selecting = new ReactiveVar(false)
  @scrolled = new ReactiveVar(false)

Template.annotatedContent.onRendered ->
  $sourceContainer = $(@data.relatedElements.sourceContainer)
  $('body').on 'mousedown', (event) =>
    # Handle triple clicks
    # Dismiss popup so it can be re-shown in correct position
    if event.originalEvent.detail == 3
      _setSelectingState(@, false)
    # Do not dismiss popup if click originated from the source text container
    if $(event.target).hasClass('source-content--wrapper')
      return
    # Allow event to propagate to 'add-incident-from-selection' button before
    # element is removed from DOM
    setTimeout =>
      _setSelectingState(@, false)
    , POPUP_DELAY
  $(@data.relatedElements.sourceContainer).on 'scroll', (event) =>
    unless @scrolled.get()
      @scrolled.set(true)

Template.annotatedContent.onDestroyed ->
  $('body').off('mousedown')

Template.annotatedContent.helpers
  annotatedContent: ->
    annotateContent(@content, @incidents.fetch())

Template.annotatedContent.events
  'mousedown .selectable-content': (event, instance) ->
    _setSelectingState(instance, false)

  'mouseup .selectable-content': _.debounce (event, instance) ->
      selection = window.getSelection()
      if not selection.isCollapsed
        data =
          source: instance.data.source
          scrolled: instance.scrolled
          selecting: instance.selecting
          popupDelay: POPUP_DELAY
        Blaze.renderWithData(
          Template.newIncidentFromSelection,
          data,
          $("#{instance.data.relatedElements.parent}")[0]
          $("#{instance.data.relatedElements.sibling}")[0]
        )
  , POPUP_DELAY
