{ annotateContent } = require('/imports/ui/annotation')

POPUP_DELAY = 100

_setSelectingState = (instance, state) ->
  instance.selecting.set(state)

Template.annotatedContent.onCreated ->
  @selecting = new ReactiveVar(false)
  @scrolled = new ReactiveVar(false)

Template.annotatedContent.onRendered ->
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
  @$('.source-content--wrapper').parent().on 'scroll', (event) =>
    unless @scrolled.get()
      @scrolled.set(true)

Template.annotatedContent.onDestroyed ->
  $('body').off('mousedown')

Template.annotatedContent.helpers
  annotatedContent: ->
    annotateContent(@content, @incidents.fetch())

Template.annotatedContent.events
  'mousedown .source-content--wrapper': (event, instance) ->
    _setSelectingState(instance, false)

  'mouseup .source-content--wrapper,
   dblclick .source-content--wrapper': _.debounce (event, instance) ->
      selection = window.getSelection()
      if not selection.isCollapsed
        data =
          selection: selection
          source: instance.data.source
          scrolled: instance.scrolled
          selecting: instance.selecting
          sourceTextContainerClass: 'curator-source-details--copy'
          popupDelay: POPUP_DELAY
        Blaze.renderWithData(
          Template.newIncidentFromSelection,
          data,
          $('.curator-source-details--copy-wrapper')[0],
          $('.curator-source-details--copy')[0]
        )
  , POPUP_DELAY
