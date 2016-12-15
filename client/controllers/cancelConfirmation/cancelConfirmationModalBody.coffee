Template.cancelConfirmationModalBody.events
  'click .confirm': (event, instance) ->
    instance.data.hasBeenWarned.set(true)
    instance.data.modalsToCancel.forEach (id) ->
      $("##{id}").modal('hide')
