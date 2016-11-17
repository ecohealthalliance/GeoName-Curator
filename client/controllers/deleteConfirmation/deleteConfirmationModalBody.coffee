commonPostDeletionTasks = (error, objNameToDelete, modalName=null) ->
  if error
    toastr.error(error.message)
    return
  modalId = if modalName then "##{modalName}" else "##{objNameToDelete}-delete-modal"
  $(modalId).modal('hide')
  $('body').removeClass 'modal-open'
  $('.modal-backdrop').remove()
  toastr.success "The #{objNameToDelete} has been deleted."

Template.deleteConfirmationModalBody.events
  'click  .delete': (event, instance) ->
    event.preventDefault()
    data = instance.data
    id = data.objId
    objNameToDelete = data.objNameToDelete

    switch objNameToDelete
      when 'incident'
        Meteor.call 'removeIncidentReport', id, (error) ->
          commonPostDeletionTasks error, objNameToDelete
          unless error
            $('.incident-report--details').closest('tr').fadeOut(-> @.remove())
      when 'source'
        Meteor.call 'removeEventSource', id, (error) ->
          commonPostDeletionTasks error, objNameToDelete
      when 'event'
        Meteor.call 'deleteUserEvent', id, (error, result) ->
          commonPostDeletionTasks error, objNameToDelete, 'edit-event-modal'
          unless error
            Router.go 'user-events'
