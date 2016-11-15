Meteor.startup ->
  $(document).on('show.bs.modal', (evt)->
    $(@).on 'keyup', (event) ->
      if event.keyCode is 27
        $('.modal').each (modal) -> $(@).modal 'hide'
  ).on 'hide.bs.modal', ->
    $(@).off 'keyup'