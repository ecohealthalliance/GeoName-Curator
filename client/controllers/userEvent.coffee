Incidents = require '/imports/collections/incidentReports.coffee'
#Allow multiple modals or the suggested locations list won't show after the loading modal is hidden
Modal.allowMultiple = true

Template.userEvent.onCreated ->
  @editState = new ReactiveVar false

Template.userEvent.onRendered ->
  new Clipboard '.copy-link'

Template.userEvent.helpers
  isEditing: ->
    return Template.instance().editState.get()

  incidentView: ->
    viewParam = Router.current().getParams()._view
    return typeof viewParam is "undefined" or viewParam is "incidents"

  locationView: ->
    return Router.current().getParams()._view is "locations"

  view: ->
    currentView = Router.current().getParams()._view
    if currentView is "locations"
      return "locationList"
    return "incidentReports"

  templateData: ->
    return Template.instance().data

Template.userEvent.events
  "click .edit-link, click #cancel-edit": (event, template) ->
    template.editState.set(not template.editState.get())


Template.summary.onCreated ->
  @copied = new ReactiveVar false

Template.summary.helpers
  formatDate: (date) ->
    return moment(date).format("MMM D, YYYY")

  articleCount: ->
    return Template.instance().data.articleCount

  caseCount: ->
    return Incidents.find({userEventId:this._id}).count()

  copied: ->
    Template.instance().copied.get()

Template.summary.events
  "click .copy-link": (event, template) ->
    copied = template.copied
    copied.set true
    setTimeout ->
      copied.set false
    , 1000

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
