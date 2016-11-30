{ commonPostDeletionTasks } = require '/imports/ui/deletion'

Template.deleteConfirmationModalBody.events
  'click  .delete': (event, instance) ->
    event.preventDefault()
    data = instance.data
    id = data.objId
    objNameToDelete = data.objNameToDelete

    switch objNameToDelete
      when 'incident'
        Meteor.call 'removeIncidentReport', id, (error) ->
          commonPostDeletionTasks(error, objNameToDelete)
          unless error
            $('.incident-report--details').closest('tr').fadeOut(-> @.remove())
      when 'source'
        Meteor.call 'removeEventSource', id, (error) ->
          commonPostDeletionTasks(error, objNameToDelete)
      when 'event'
        Meteor.call 'deleteUserEvent', id, (error, result) ->
          commonPostDeletionTasks(error, objNameToDelete, 'edit-event-modal')
          unless error
            Router.go 'user-events'
      when 'feed'
        Meteor.call 'removeFeed', id, (error) ->
          commonPostDeletionTasks(error, objNameToDelete)
