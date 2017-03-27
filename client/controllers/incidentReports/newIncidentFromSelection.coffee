{ buildAnnotatedIncidentSnippet } = require('/imports/ui/annotation')

POPUP_DELAY = 200
POPUP_PADDING = 5
POPUP_PADDING_TOP = 20
POPUP_WINDOW_PADDING = 50

_getAnnotationData = (selection) ->
  range = selection.getRangeAt(0)
  textOffsets = [range.startOffset, range.endOffset]
  content = selection.anchorNode.textContent

  textOffsets: textOffsets
  text: content.slice(textOffsets[0], textOffsets[1])

Template.newIncidentFromSelection.onCreated ->
  @selection = window.getSelection()
  @selecting = @data.selecting
  @selecting.set(true)
  range = @selection.getRangeAt(0)
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

  annotatedText: ->
    instance = Template.instance()
    _getAnnotationData(instance.selection).text

Template.newIncidentFromSelection.events
  'click .add-incident-from-selection': (event, instance) ->
    source = instance.data.source
    incident =
      annotations:
        case: [_getAnnotationData(instance.selection)]
    snippetHtml = buildAnnotatedIncidentSnippet(source.content, incident)
    Modal.show 'suggestedIncidentModal',
      add: true
      articles: [source]
      incident: incident
      incidentText: Spacebars.SafeString(snippetHtml)
      offCanvasStartPosition: 'top'

    window.getSelection().removeAllRanges()
