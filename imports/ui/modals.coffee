module.exports =
  ###
  # dismissModal - Dismisses modals manually
  #
  # @param {string} element, class or id of element
  ###
  dismissModal: (element) ->
    $(element).modal 'hide'
    $('.modal-backdrop').remove()
    $('body').removeClass 'modal-open'

  ###
  # stageModals - Manages which modal is (un)staged or dismissed
  #
  # @param {obj} instance, template instace of modal
  # @param {obj} modals, modals to (un)stage and classes to add remove
  # @param {boolean} hideModal, if the modal should be hidden and removed
  ###
  stageModals: (instance, modals, hideModal=true) ->
    { currentModal, previousModal } = modals
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
