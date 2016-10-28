import UserEvents from '/imports/collections/userEvents.coffee'
import CuratorSources from '/imports/collections/curatorSources.coffee'

###
# Template.suggestedEvents - creates a reactive table to be display as part of
#   the curatorInbox -> curatorEvents views.  The table is populated by a
#   remove server-side meteor method that performs a full-text search on the
#   UserEvents collection. The result is sorted by highest score.
#
#   The table is reactively updated by an autorun that listens to changes
#   on the Template.currentEvents reactive var `associatedEventIdsToArticles`.
#   Note: this reactive var is passed to this template throught jade.
###

Template.suggestedEvents.onCreated ->
  @isOpen = new ReactiveVar(true)
  @events = new ReactiveVar([])
  @initialEvents = []

  # sets the suggestedEvents table fields
  @eventFields = [
    {
      key: 'score'
      label: ''
      sortOrder: 1
      sortDirection: 'descending'
      hidden: true
    },
    {
      key: 'eventName'
      label: ''
      tmpl: Template.curatorEventSearchRow
    }
  ]

  ###
  # updateSuggestedEvents - takes the result of a reactive computation and
  #   updates the suggested events array by computing the difference.
  #
  # @param {object} associated, the object's keys contains the userEventId of
  #   associated UserEvents
  ###
  @updateSuggestedEvents = (associated) =>
    suggestedUserEventIds = _.pluck(@initialEvents, '_id')
    associatedUserEventIds = Object.keys(associated)
    diff = _.difference(suggestedUserEventIds, associatedUserEventIds)
    events = _.filter(@initialEvents, (e) -> diff.indexOf(e._id) >= 0)
    @events.set(events)

  @autorun =>
    source = CuratorSources.find({_id: @data.selectedSourceId.get()}).fetch()[0]
    if source
      # strip punctuation and create tokens
      tokens = if source.title then source.title.replace(/[~`!@#$%^&*(){}\[\];:"'<,.>?\/\\|_+=-]/g, '').split(' ') else []
      # remove the first token from the search string (PRO/AH/EDR> without the special chars)
      # TODO: this is domain specific to ProMed. If other feeds are added, we would
      # need to do some conditional logic `if feed.isPromed then remove first token`.
      search = if tokens.length > 1 then tokens.slice(1, tokens.length).join(' ') else ''

      # call the server-side meteor method to perform full-text search sorted by score
      Meteor.call 'searchUserEvents', search, (err, res) =>
        if err
          return
        # set the initialEvents to the result and update the reactive array
        @initialEvents = res
        @events.set(res)

  # reactively compute changes to associatedEventIdsToArticles object and
  # update the suggested events
  @autorun =>
    if @data.associatedEventIdsToArticles
      associated = @data.associatedEventIdsToArticles.get()
      @updateSuggestedEvents(associated)

Template.suggestedEvents.helpers
  # controls the visiblity of the suggested-events-table and toggles the chevron
  isOpen: ->
    Template.instance().isOpen.get()
  # the reactive array that populates the reactive-`table
  events: ->
    Template.instance().events.get()
  # settings for the reactive-table
  settings: ->
    fields = Template.instance().eventFields
    return {
      id: 'suggested-events-table'
      noDataTmpl: Template.noCuratorEvents
      fields: fields
      showRowCount: false
      showFilter: false
      showColumnToggles: false
      showNavigationRowsPerPage: false
      showNavigation: 'never'
      currentPage: 1
      rowsPerPage: 5
      class: "table table-hover col-sm-12"
    }

Template.suggestedEvents.events
  # event handler to toggle the reactive var isOpen
  'click .curator-collapse': (event, template) ->
    if template.isOpen.get()
      template.isOpen.set false
    else
      template.isOpen.set true
