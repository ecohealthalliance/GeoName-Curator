{ annotateContent } = require('/imports/ui/annotation')

_dismissPopup = ->
  $popup = $('.new-incident-from-selection')
  $popup.removeClass('active')
  setTimeout ->
    $popup.remove()
  , 300

Template.annotatedContent.onRendered ->
  $('body').on 'mousedown', (event) ->
    # Handle triple clicks
    # Dismiss popup so it can be re-shown in correct position
    if event.originalEvent.detail == 3
      _dismissPopup()
    # Do not dismiss popup if click originated from the source text container
    if $(event.target).hasClass('source-content--wrapper')
      return
    # Allow event to propagate to 'add-incident-from-selection' button before
    # element is removed from DOM
    setTimeout ->
      _dismissPopup()
    , 200

Template.annotatedContent.onDestroyed ->
  $('body').off('mousedown')

Template.annotatedContent.helpers
  annotatedContent: ->
    annotateContent(@content, @incidents.fetch())

Template.annotatedContent.events
  'mouseup .source-content--wrapper,
   dblclick .source-content--wrapper': (event, instance) ->
    Meteor.defer ->
      selection = window.getSelection()
      _dismissPopup()
      if not selection.isCollapsed
        data =
          selection: selection
          source: instance.data.source
        Blaze.renderWithData Template.newIncidentFromSelection, data, $('body')[0]
