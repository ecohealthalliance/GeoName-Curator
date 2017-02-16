module.exports =
  dismissModal: (element) ->
    $('#create-event-modal').modal 'hide'
    $('.modal-backdrop').remove()
    $('body').removeClass 'modal-open'

  stageModals: (instance, modals, hideModal=true) ->
    { currentModal, previousModal } = modals
    $(currentModal.element)
      .removeClass("in #{currentModal?.remove}")
      .addClass("out #{currentModal?.add}")
    if previousModal
      $(previousModal.element)
        .addClass("in #{previousModal?.add}")
    if hideModal
      setTimeout ->
        Modal.hide(instance)
      , 500
