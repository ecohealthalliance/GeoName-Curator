module.exports =
  dismissModal: (element) ->
    $('#create-event-modal').modal 'hide'
    $('.modal-backdrop').remove()
    $('body').removeClass 'modal-open'

  stageModals: (instance, modals, hideModal=true) ->
    { currentModal, previousModal } = modals
    # Ensure associated events
    currentModal.remove += ' in'
    currentModal.add += if hideModal then ' out' else ''
    if previousModal
      previousModal.remove += ' out'
      previousModal.add += ' in'

    $(currentModal.element)
      .removeClass(currentModal.remove)
      .addClass(currentModal?.add)
    if previousModal
      $(previousModal.element)
        .removeClass(previousModal.remove)
        .addClass(previousModal.add)
    if hideModal
      setTimeout ->
        Modal.hide(instance)
      , 500
