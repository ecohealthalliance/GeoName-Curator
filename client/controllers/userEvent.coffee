Incidents = require '/imports/collections/incidentReports.coffee'
#Allow multiple modals or the suggested locations list won't show after the loading modal is hidden
Modal.allowMultiple = true

Template.userEvent.onCreated ->
  @editState = new ReactiveVar false

Template.userEvent.onRendered ->
  new Clipboard '.copy-link'

Template.userEvent.helpers
  isEditing: ->
    Template.instance().editState.get()

  incidentView: ->
    viewParam = Router.current().getParams()._view
    typeof viewParam is 'undefined' or viewParam is 'incidents'

  locationView: ->
    Router.current().getParams()._view is 'locations'

  view: ->
    currentView = Router.current().getParams()._view
    if currentView is 'locations'
      return 'locationList'
    'incidentReports'

  templateData: ->
    Template.instance().data

Template.userEvent.events
  'click .edit-link, click #cancel-edit': (event, template) ->
    template.editState.set(not template.editState.get())

Template.summary.onCreated ->
  @copied = new ReactiveVar false

Template.summary.helpers
  formatDate: (date) ->
    moment(date).format('MMM D, YYYY')

  articleCount: ->
    Template.instance().data.articleCount

  caseCount: ->
    Incidents.find({userEventId:this._id}).count()

  copied: ->
    Template.instance().copied.get()

Template.summary.events
  'click .copy-link': (event, template) ->
    copied = template.copied
    copied.set true
    setTimeout ->
      copied.set false
    , 1000

Template.createEvent.events
  'submit #add-event': (event) ->
    target = event.target
    eventName = target.eventName
    event.preventDefault()
    valid = eventName.checkValidity()
    unless valid
      toastr.error('Please specify a valid name')
      eventName.focus()
      return
    newEvent = eventName.value
    summary = target.eventSummary.value

    Meteor.call 'editUserEvent', null, newEvent, summary, (error, result) ->
      if result
        Router.go 'user-event', _id: result.insertedId
