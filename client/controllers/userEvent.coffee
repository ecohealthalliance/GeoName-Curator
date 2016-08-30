#Allow multiple modals or the suggested locations list won't show after the loading modal is hidden
Modal.allowMultiple = true

Template.userEvent.onCreated ->
  @editState = new ReactiveVar(false)

Template.userEvent.onRendered ->
  $(document).ready ->
    board = new Clipboard("#copyLink")
    $(document.body).on("focus", "#eventLink", ->
      $(this).select()
    )

Template.userEvent.helpers
  isEditing: ->
    return Template.instance().editState.get()
  locationView: ->
    currentRoute = Router.current().route.getName()
    return currentRoute is "event-locations" or currentRoute is "user-event"
  incidentView: ->
    return Router.current().route.getName() is "event-incidents"
  view: ->
    currentRoute = Router.current().route.getName()
    if currentRoute is "event-incidents"
      return "incidentReports"
    return "locationList"
  templateData: ->
    return Template.instance().data

Template.userEvent.events
  "click .edit-link, click #cancel-edit": (event, template) ->
    template.editState.set(not template.editState.get())
  "click .delete-link": (event, template) ->
    if confirm("Are you sure you want to delete this event?")
      Meteor.call("deleteUserEvent", @_id, (error, result) ->
        if not error
          Router.go('user-events')
      )
  "submit #editEvent": (event, template) ->
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
      Meteor.call("updateUserEvent", @_id, updatedName, updatedSummary, disease, (error, result) ->
        if not error
          template.editState.set(false)
      )

Template.createEvent.events
  "submit #add-event": (e) ->
    e.preventDefault()
    valid = e.target.eventName.checkValidity()
    unless valid
      toastr.error('Please specify a valid name')
      e.target.eventName.focus()
      return
    newEvent = e.target.eventName.value
    summary = e.target.eventSummary.value

    Meteor.call("addUserEvent", newEvent, summary, (error, result) ->
      if result
        Router.go('user-event', {_id: result})
    )
