CuratorSources = require '/imports/collections/curatorSources.coffee'
key = require 'keymaster'

markReviewed = (instance) ->
  reviewed = instance.reviewed
  notifying = instance.notifying
  reviewed.set not reviewed.get()
  Meteor.call('markSourceReviewed', instance.source.get()._id, reviewed.get())
  if reviewed.get()
    notifying.set true
    Meteor.setTimeout ->
      unReviewedQuery = $and: [ {reviewed: false}, instance.data.query.get()]
      nextSource = CuratorSources.findOne unReviewedQuery,
        sort:
          publishDate: -1
      instance.data.selectedSourceId.set nextSource._id
      notifying.set false
    , 1200

Template.curatorSourceDetails.onCreated ->
  @contentIsOpen = new ReactiveVar(false)
  @notifying = new ReactiveVar false
  @source = new ReactiveVar null
  @reviewed = new ReactiveVar false

Template.curatorSourceDetails.onRendered ->
  Meteor.defer =>
    @$('[data-toggle=tooltip]').tooltip
      delay: show: '300'

  # Create key binding which marks sources as reviewed.
  key 'ctrl + enter, command + enter', (event) =>
    markReviewed(@)

  @autorun =>
    sourceId = Template.instance().data.selectedSourceId.get()
    source = CuratorSources.findOne _id: sourceId
    @reviewed.set source?.reviewed or false
    @source.set source

Template.curatorSourceDetails.helpers
  source: ->
    Template.instance().source.get()

  contentIsOpen: ->
    Template.instance().contentIsOpen.get()

  formattedScrapeDate: ->
    moment(Template.instance().data.sourceDate).format('MMMM DD, YYYY')

  formattedPromedDate: ->
    moment(Template.instance().data.promedDate).format('MMMM DD, YYYY')

  isReviewed: ->
    Template.instance().source.get().reviewed

  notifying: ->
    Template.instance().notifying.get()

  selectedSourceId: ->
    Template.instance().data.selectedSourceId

Template.curatorSourceDetails.events
  "click .toggle-reviewed": (event, instance) ->
    markReviewed(instance)

  'click .toggle-source-content': (event, instance) ->
    open = instance.contentIsOpen
    open.set not open.get()
    $(event.currentTarget).tooltip 'destroy'
