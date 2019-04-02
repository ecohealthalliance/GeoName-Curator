require '/imports/ui/helpers.coffee'

redirectIfNotAuthorized = (router, roles) ->
  unless Meteor.userId() and roles.length
    router.redirect '/sign-in'
    return

  unless Roles.userIsInRole(Meteor.userId(), roles)
    if Meteor.userId()
      router.redirect '/about'
    else
      router.redirect '/sign-in'
  router.next()

Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"

Router.onBeforeAction ->
  routeTitle = @route.options.title
  title = 'GeoName Annotator'
  if _.isString(routeTitle)
    title += ": #{routeTitle}"
  else if _.isFunction(routeTitle)
    title += ": #{routeTitle.call(@)}"
  document.title = title
  @next()

Router.onAfterAction ->
  window.scroll 0, 0

Router.route "/",
  name: 'splash'
  action: ->
    @redirect '/curator-inbox'

Router.route "/about",
  title: 'About'

Router.route "/admins",
  name: 'admins'
  title: 'Manage User Accounts'
  onBeforeAction: ->
    redirectIfNotAuthorized(@, ['admin'])
  waitOn: ->
    Meteor.subscribe "allUsers"
  data: ->
    adminUsers: Meteor.users.find({ roles: {$in: ["admin"]} }, {sort: {'profile.name': 1}})
    curatorUsers: Meteor.users.find({ roles: {$in: ["curator"] }}, {sort: {'profile.name': 1}})
    defaultUsers: Meteor.users.find({ roles: {$not: {$in: ["admin", "curator"]} }}, {sort: {'profile.name': 1}})

Router.route "/curator-inbox",
  name: 'curator-inbox'
  title: 'Curator Inbox'
  waitOn: -> [Roles.subscription, Meteor.subscribe('user')]
  onBeforeAction: ->
    redirectIfNotAuthorized(@, ['admin', 'curator'])

Router.route "/curator-inbox/article/:articleId/:incidentId",
  name: 'curator-inbox-article'
  template: 'curatorInbox'
  title: 'Curator Inbox'
  waitOn: -> [Roles.subscription, Meteor.subscribe('user')]
  onBeforeAction: ->
    redirectIfNotAuthorized(@, ['admin', 'curator'])
