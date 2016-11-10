Template.incidentDeleteModal.helpers
  getFirstLocation: () ->
    Template.instance().data.locations[0].name
  formatDate: (date) ->
    moment(date).format("MMM D, YYYY")

Template.incidentDeleteModal.events
  'click .delete-event-confirmation': (event, instance) ->
    Meteor.call 'removeIncidentReport', instance.data._id, (error) ->
      if error
        toastr.error(error.message)
        return
      $('#incident-delete-modal').modal('hide')
      $('body').removeClass 'modal-open'
      $('.modal-backdrop').remove()
      $('.incident-report--details').closest('tr').fadeOut(-> @.remove())
      toastr.success('The incident has been deleted.')
