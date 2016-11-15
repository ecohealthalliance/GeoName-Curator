Incidents = require '/imports/collections/incidentReports.coffee'

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

  allowAddingReports: ->
    Template.instance().articleCount and not Incidents.findOne(userEventId:this._id)

Template.summary.events
  'click .copy-link': (event, template) ->
    copied = template.copied
    copied.set true
    setTimeout ->
      copied.set false
    , 1000
