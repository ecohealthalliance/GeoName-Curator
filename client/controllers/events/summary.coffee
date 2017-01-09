Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'

Template.summary.onCreated ->
  @copied = new ReactiveVar false
  @collapsed = new ReactiveVar false

Template.summary.onRendered ->
  @autorun =>
    UserEvents.findOne(@data._id)
    Meteor.defer =>
      if @$('.summary span').height() > 400
        @collapsed.set true
      else
        @collapsed.set false

Template.summary.helpers
  formatDate: (date) ->
    moment(date).format('MMM D, YYYY')

  articleCount: ->
    Template.instance().data.articleCount

  caseCount: ->
    Incidents.find({userEventId:this._id}).count()

  copied: ->
    Template.instance().copied.get()

  collapsed: ->
    Template.instance().collapsed.get()

Template.summary.events
  'click .copy-link': (event, template) ->
    copied = template.copied
    copied.set true
    setTimeout ->
      copied.set false
    , 1000

  'click .expand': (event, template) ->
    template.collapsed.set false
