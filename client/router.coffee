require '/imports/ui/helpers.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'
Articles = require '/imports/collections/articles.coffee'

Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"

Router.onAfterAction ->
  window.scroll 0, 0

Router.route "/",
  name: 'splash'

Router.route "/about"

Router.route "/event-map",
  name: 'event-map'
  waitOn: ->
    Meteor.subscribe "userEvents"
    Meteor.subscribe "mapIncidents"

Router.route "/admins",
  name: 'admins'
  onBeforeAction: ->
    unless Roles.userIsInRole(Meteor.userId(), ['admin'])
      @redirect '/'
    @next()
  waitOn: ->
    Meteor.subscribe "allUsers"
  data: ->
    adminUsers: Meteor.users.find({ roles: {$in: ["admin"]} }, {sort: {'profile.name': 1}})
    curatorUsers: Meteor.users.find({ roles: {$in: ["curator"], $not: {$in: ["admin"]} }}, {sort: {'profile.name': 1}})
    defaultUsers: Meteor.users.find({ roles: {$not: {$in: ["admin", "curator"]} }}, {sort: {'profile.name': 1}})

Router.route "/create-account",
  name: 'create-account'
  onBeforeAction: () ->
    unless Roles.userIsInRole(Meteor.userId(), ['admin'])
      @redirect '/'
    @next()
  waitOn: ()->
    #Wait on roles subscription so onBeforeAction() doesn't run twice
    Meteor.subscribe "roles"

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

Router.route "/contact-us",
  name: 'contact-us'

Router.route "/user-events",
  name: 'user-events'

Router.route "/curator-inbox",
  name: 'curator-inbox'
  waitOn: ->
    Meteor.subscribe "userEvents"
  onBeforeAction: () ->
    unless Roles.userIsInRole(Meteor.userId(), ['admin', 'curator'])
      @redirect '/sign-in'
    @next()

Router.route "/user-event/:_id/:_view?",
  name: 'user-event'
  waitOn: ->
    [
      Meteor.subscribe "userEvent", @params._id
      Meteor.subscribe "eventArticles", @params._id
      Meteor.subscribe "eventIncidents", @params._id
    ]
  data: ->
    userEvent: UserEvents.findOne({'_id': @params._id})
    articles: Articles.find({'userEventId': @params._id}, {sort: {publishDate: -1}}).fetch()
    incidents: Incidents.find({'userEventId': @params._id}, {sort: {date: -1}}).fetch()
