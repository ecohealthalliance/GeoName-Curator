{ annotateContentWithIncidents } = require('/imports/ui/annotation')

POPUP_DELAY = 100


Template.annotatedContent.onCreated ->
  @selecting = new ReactiveVar(false)
  @scrolled = new ReactiveVar(false)

Template.annotatedContent.onRendered ->
  $('body').on 'mousedown', (event) =>
    if $(event.target).closest('.new-incident-from-selection').length == 0
      @selecting.set(false)
  $(@data.relatedElements.sourceContainer).on 'scroll', (event) =>
    unless @scrolled.get()
      @scrolled.set(true)

Template.annotatedContent.onDestroyed ->
  $('body').off('mousedown')

Template.annotatedContent.helpers
  annotatedContent: ->
    annotateContentWithIncidents(@content, @incidents.fetch())

Template.annotatedContent.events
  'mouseup .selectable-content': (event, instance) ->
    instanceData = instance.data
    selection = window.getSelection()
    instance.scrolled.set(false)
    if not selection.isCollapsed and selection.toString().trim()
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
    else
      $currentTarget = $(event.currentTarget)
      # Temporarily 'shuffle' the text layers so selectable-content is on
      # bottom and annotated-content is on top
      $currentTarget.css('z-index', -1)
      # Get element based on location of click event
      elementAtPoint = document.elementFromPoint(event.clientX, event.clientY)
      annotationId = elementAtPoint.getAttribute('data-incident-id')
      if annotationId
        # Set reactive variable that's handed down from curatorSourceDetails and
        # shared with the incidentTable templates to the clicked annotation's ID
        data =
          incidentId: annotationId
          source: instanceData.source
          scrolled: instance.scrolled
          relatedElements: instanceData.relatedElements
          allowRepositioning: false
          view: 'annotationOptions'
  
        Blaze.renderWithData(
          Template.popup,
          data,
          $("#{instance.data.relatedElements.parent}")[0]
          $("#{instance.data.relatedElements.sibling}")[0]
        )
      # Return selectable-content to top so user can make selection
      $currentTarget.css('z-index', 3)
