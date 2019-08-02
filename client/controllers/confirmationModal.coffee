Template.confirmationModal.events
  'click .confirm': (event, instance) ->
    event.preventDefault()
    data = instance.data
    data.actionCallback(->
      $("#confirmation-modal").modal('hide')
      $('body').removeClass('modal-open')
      $('.modal-backdrop').remove()
    )
