module.exports =
  commonPostDeletionTasks: (error, objNameToDelete, modalName=null) ->
    if error
      toastr.error(error.message)
      return
    modalId = if modalName then "##{modalName}" else "##{objNameToDelete}-delete-modal"
    $(modalId).modal('hide')
    $('body').removeClass('modal-open')
    $('.modal-backdrop').remove()
    toastr.success("The #{objNameToDelete} has been deleted.")
