POPUP_PADDING = 0
POPUP_PADDING_TOP = 20
POPUP_WINDOW_PADDING = 50

Template.newIncidentFromSelection.onCreated ->
  selection = window.getSelection()
  range = selection.getRangeAt(0)
  {top, bottom, left, width} = range.getBoundingClientRect()
  selectionHeight = bottom - top
  topPosition = Math.floor(top + selectionHeight + POPUP_PADDING)
  bottomPosition = 'auto'
  # Handle case when selection is near bottom of window
  if (bottom + POPUP_WINDOW_PADDING) > window.innerHeight
    topPosition = 'auto'
    bottomPosition = window.innerHeight - top + POPUP_PADDING_TOP
  @popupPosition =
    top: topPosition
    bottom: bottomPosition
    left:  Math.floor(left + width / 2)

Template.newIncidentFromSelection.onRendered ->
  Meteor.defer =>
    @$('.new-incident-from-selection').addClass('active')

Template.newIncidentFromSelection.helpers
  topPosition: ->
    Template.instance().popupPosition.top

  leftPosition: ->
    Template.instance().popupPosition.left

  bottomPosition: ->
    Template.instance().popupPosition.bottom

Template.newIncidentFromSelection.events
  'click .add-incident-from-selection': (event, instance) ->
    selection = window.getSelection()
    content = selection.baseNode.textContent
    textOffsets = [selection.baseOffset, selection.extentOffset]
    Modal.show 'incidentModal',
      incident: null
      articles: [instance.data.source]
      add: true
      accept: true
      manualAnnotation:
        textOffsets: textOffsets
        text: content.slice(textOffsets[0], textOffsets[1])
