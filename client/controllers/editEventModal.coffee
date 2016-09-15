Template.editEventDetailsModal.onCreated ->
  @confirmingDeletion = new ReactiveVar false

Template.editEventDetailsModal.onRendered ->
  instance = @
  @$('#edit-event-modal').on 'show.bs.modal', (event) ->
    instance.confirmingDeletion.set false
    fieldToEdit = $(event.relatedTarget).data('editing')
    # Wait for the the modal to open
    # then focus input based on which edit button the user clicks
    Meteor.setTimeout () ->
      field = switch fieldToEdit
        when 'disease' then 'input[name=eventDisease]'
        when 'summary' then 'textarea'
        else 'input:first'
      instance.$(field).focus()
    , 500

Template.editEventDetailsModal.helpers
  confirmingDeletion: ->
    Template.instance().confirmingDeletion.get()

Template.editEventDetailsModal.events
  'submit #editEvent': (event, template) ->
    event.preventDefault()
    valid = event.target.eventName.checkValidity()
    unless valid
      toastr.error('Please provide a new name')
      event.target.eventName.focus()
      return
    updatedName = event.target.eventName.value.trim()
    updatedSummary = event.target.eventSummary.value.trim()
    disease = event.target.eventDisease.value.trim()
    if updatedName.length isnt 0
      Meteor.call 'updateUserEvent', @_id, updatedName, updatedSummary, disease, (error, result) ->
        if not error
          $('#edit-event-modal').modal 'hide'

  'click .delete-event': (event, instance) ->
    instance.confirmingDeletion.set true

  'click .back-to-editing': (event, instance) ->
    instance.confirmingDeletion.set false

  'click .delete-event-confirmation': (event, instance) ->
    Meteor.call 'deleteUserEvent', @_id, (error, result) ->
      if not error
        instance.$('#edit-event-modal').modal('hide')
        $('.modal-backdrop').remove()
        $('body').removeClass 'modal-open'
        Router.go 'user-events'
