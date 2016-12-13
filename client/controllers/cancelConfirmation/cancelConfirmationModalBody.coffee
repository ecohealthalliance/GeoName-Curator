Template.cancelConfirmationModalBody.events
  'click .confirm': (event, instance) ->
    instance.data.modalsToCancel.forEach (id) ->
      $("##{id}").modal('hide')
