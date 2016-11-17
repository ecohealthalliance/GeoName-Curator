module.exports =
  dismissModal: (element) ->
    $('#create-event-modal').modal 'hide'
    $('.modal-backdrop').remove()
    $('body').removeClass 'modal-open'
