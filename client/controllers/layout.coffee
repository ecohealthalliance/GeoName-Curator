Template.layout.events
  # handles closing modals using the escape key when there are multiple modals on the same page
  'keyup': (event, template) ->
    if event.keyCode is 27
      $('.modal').each (modal) -> $(@).modal 'hide'