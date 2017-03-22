POPUP_DELAY = 200
POPUP_PADDING = 5
POPUP_PADDING_TOP = 20
POPUP_WINDOW_PADDING = 50

Template.newIncidentFromSelection.onCreated ->
  @selecting = @data.selecting
  @selecting.set(true)
  selection = window.getSelection()
  range = selection.getRangeAt(0)
  {top, bottom, left, width} = range.getBoundingClientRect()
  selectionHeight = bottom - top
  topPosition = "#{Math.floor(top + selectionHeight + POPUP_PADDING)}px"
  bottomPosition = 'auto'
  # Handle case when selection is near bottom of window
  if (bottom + POPUP_WINDOW_PADDING) > window.innerHeight
    topPosition = 'auto'
    bottomPosition = "#{window.innerHeight - top + POPUP_PADDING_TOP}px"
  @popupPosition =
    top: topPosition
    bottom: bottomPosition
    left:  "#{Math.floor(left + width / 2)}px"

Template.newIncidentFromSelection.onRendered ->
  Meteor.setTimeout =>
    @$('.new-incident-from-selection').addClass('active')
  , @data.popupDelay or POPUP_DELAY

  @autorun =>
    if not @selecting.get()
      @$('.new-incident-from-selection').remove()
      @data.scrolled.set(false)

Template.newIncidentFromSelection.helpers
  topPosition: ->
    Template.instance().popupPosition.top

  leftPosition: ->
    Template.instance().popupPosition.left

  bottomPosition: ->
    Template.instance().popupPosition.bottom

  scrolled: ->
    Template.instance().data.scrolled.get()

Template.newIncidentFromSelection.events
  'click .add-incident-from-selection': (event, instance) ->
    selection = window.getSelection()
    content = selection.baseNode.textContent
    textOffsets = [selection.baseOffset, selection.extentOffset]
    selection.removeAllRanges()
    Modal.show 'incidentModal',
      incident: null
      articles: [instance.data.source]
      add: true
      accept: true
      manualAnnotation:
        textOffsets: textOffsets
        text: content.slice(textOffsets[0], textOffsets[1])
