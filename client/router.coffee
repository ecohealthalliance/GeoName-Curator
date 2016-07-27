Events = ->
  @grid.Events

Fields = ->
  @grid.Fields

Comments = ->
  @grid.Comments

UserEvents = ->
  @grid.UserEvents

Articles = ->
  @grid.Articles

Geolocations = () ->
  @grid.Geolocations

Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"

Router.onRun ->
  if Session.equals('AnalyticsJS_loaded', true)
    analytics.page @path
  @next()

Router.onAfterAction ->
  window.scroll 0, 0

Router.route "/",
  name: 'splash'

Router.route "/about"

Router.route "/events",
  waitOn: ->
    [
      Meteor.subscribe "fields"
    ]
  data: ->
    fields: Fields().find({'Event table': {'$ne': '0'}})

Router.route "/event/:eidID",
  name: 'event'
  waitOn: ->
    [
      Meteor.subscribe "event", @params.eidID
      Meteor.subscribe "fields"
      Meteor.subscribe "comments", @params.eidID
      Meteor.subscribe "references", @params.eidID
    ]
  data: ->
    event: Events().findOne({'eidID': @params.eidID})
    comments: Comments().find({'event': @params.eidID}, {sort: {timeStamp: -1}})

Router.route "/event-map",
  name: 'event-map'
  waitOn: ->
    Meteor.subscribe "geolocations"
    Meteor.subscribe "userEvents"
  data: ->
    events: UserEvents()
    locations: Geolocations()

Router.route "/admins",
  name: 'admins'
  onBeforeAction: ->
    unless Roles.userIsInRole(Meteor.userId(), ['admin'])
      @redirect '/'
    @next()
  waitOn: ->
    Meteor.subscribe "allUsers"
  data: ->
    adminUsers: Meteor.users.find({roles: {$in: ["admin"]}})
    nonAdminUsers: Meteor.users.find({roles: {$not: {$in: ["admin"]}}})

Router.route "/create-account",
  name: 'create-account'
  onBeforeAction: () ->
    unless Roles.userIsInRole(Meteor.userId(), ['admin'])
      @redirect '/'
    @next()
  waitOn: ()->
    #Wait on roles subscription so onBeforeAction() doesn't run twice
    Meteor.subscribe "roles"

Router.route "/comments",
  name: 'adminComments'
  onBeforeAction: ->
    unless Roles.userIsInRole(Meteor.userId(), ['admin'])
      @redirect '/'
    @next()
  waitOn: ->
    Meteor.subscribe "adminComments"
  data: ->
    comments: Comments().find({}, {sort: {timeStamp: -1}})

Router.route "/download",
  name: 'download',
  onBeforeAction: ->
    unless Meteor.userId()
      @redirect '/sign-in'
    @next()
  action: ->
    @render('preparingDownload')
    controller = @
    Meteor.call('download', (err, result) ->
      unless err
        csvData = "data:text/csv;charset=utf-8," + result.csv
        jsonData = "data:application/json;charset=utf-8," + result.json
        controller.render('download',
          data:
            jsonData: encodeURI(jsonData)
            csvData: encodeURI(csvData)
        )
    )

Router.route "/variable-definitions",
  name: 'variable-definitions',
  waitOn: ->
    [
      Meteor.subscribe "fields"
    ]
  data: ->
    fields: Fields().find({'tab': {'$ne': ''}, 'webVariable': {'$ne': '0'}})

Router.route "/create-event",
  name: 'create-event',
  onBeforeAction: () ->
    unless Roles.userIsInRole(Meteor.userId(), ['admin'])
      @redirect '/sign-in'
    @next()

Router.route "/contact-us",
  name: 'contact-us'
  
Router.route "/user-events",
  name: 'user-events'

Router.route "/user-event/:_id",
  name: 'user-event'
  waitOn: ->
    [
      Meteor.subscribe "userEvent", @params._id
      Meteor.subscribe "eventArticles", @params._id
      Meteor.subscribe "eventLocations", @params._id
    ]
  data: ->
    userEvent: UserEvents().findOne({'_id': @params._id})
    articles: Articles().find({'userEventId': @params._id}).fetch()
    locations: Geolocations().find({'userEventId': @params._id}).fetch()
