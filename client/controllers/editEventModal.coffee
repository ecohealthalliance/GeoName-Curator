CuratorSources = require '/imports/collections/curatorSources.coffee'
{ dismissModal } = require '/imports/ui/modals'

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

  adding: ->
    Template.instance().data.action is 'add'

Template.editEventDetailsModal.events
  'submit #editEvent': (event, instance) ->
    event.preventDefault()
    valid = event.target.eventName.checkValidity()
    unless valid
      toastr.error('Please provide a new name')
      event.target.eventName.focus()
      return
    name = event.target.eventName.value.trim()
    summary = event.target.eventSummary.value.trim()
    disease = event.target.eventDisease?.value.trim()
    if name.length isnt 0
      source = CuratorSources.findOne(instance.data.sourceId)
      eventId = @_id
      Meteor.call 'editUserEvent', eventId, name, summary, disease, (error, result) ->
        if not error
          Modal.hide 'editEventDetailsModal'
          $('#edit-event-modal').modal('hide')
          if instance.data.addToSource
            Meteor.call 'addEventSource',
              url: "promedmail.org/post/#{source._sourceId}"
              userEventId: result.insertedId
              title: source.title
              publishDate: source.publishDate
              publishDateTZ: "EST"

  'click .delete-event': (event, instance) ->
    instance.confirmingDeletion.set true

  'click .back-to-editing': (event, instance) ->
    instance.confirmingDeletion.set false
