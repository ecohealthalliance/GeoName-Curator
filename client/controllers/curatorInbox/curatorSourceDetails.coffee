CuratorSources = require '/imports/collections/curatorSources.coffee'
key = require 'keymaster'

_markReviewed = (instance, showNext=true) ->
  new Promise (resolve) ->
    reviewed = instance.reviewed
    notifying = instance.notifying
    reviewed.set not reviewed.get()
    Meteor.call('markSourceReviewed', instance.source.get()._id, reviewed.get())
    if reviewed.get()
      notifying.set true
      Meteor.setTimeout ->
        if showNext
          unReviewedQuery = $and: [ {reviewed: false}, instance.data.query.get()]
          nextSource = CuratorSources.findOne unReviewedQuery,
            sort:
              publishDate: -1
          instance.data.selectedSourceId.set nextSource._id
        notifying.set false
        resolve()
      , 1200

_getSource = (instance, sourceId) ->
  source = CuratorSources.findOne
    _id: sourceId
  instance.reviewed.set source?.reviewed or false
  instance.source.set source

Template.curatorSourceDetails.onCreated ->
  @contentIsOpen = new ReactiveVar(false)
  @notifying = new ReactiveVar false
  @source = new ReactiveVar null
  @reviewed = new ReactiveVar false

Template.curatorSourceDetails.onRendered ->
  instance = @
  Meteor.defer =>
    instance.$('[data-toggle=tooltip]').tooltip
      delay: show: '300'
      container: 'body'
    if window.innerWidth <= 1000
      Hamer = require 'hammerjs'
      swippablePane = new Hammer($('#touch-stage')[0])
      swippablePane.on 'swiperight', (event) ->
        instance.data.currentPaneInView.set('')

  @autorun =>
    title = instance.source.get()?.title
    Meteor.defer =>
      $title = $('#sourceDetailsTitle')
      titleEl = $title[0]
      # Remove title and tooltip if the title is complete & without ellipsis
      if titleEl.offsetWidth >= titleEl.scrollWidth
        $title.tooltip('hide').attr('data-original-title', '')
      else
        $title.attr('data-original-title', title)

  # Create key binding which marks sources as reviewed.
  key 'ctrl + enter, command + enter', (event) =>
    _markReviewed(@)

  @autorun ->
    sourceId = instance.data.selectedSourceId.get()
    _getSource(instance, sourceId)

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
    _markReviewed(instance)

  'click .toggle-source-content': (event, instance) ->
    open = instance.contentIsOpen
    open.set not open.get()
    $(event.currentTarget).tooltip 'destroy'

  'click .back-to-list': (event, instance) ->
    instance.data.currentPaneInView.set('')
