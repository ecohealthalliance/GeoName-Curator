Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'
Articles = require '/imports/collections/articles.coffee'
Feeds = require '/imports/collections/feeds.coffee'

# Incidents
ReactiveTable.publish 'curatorEventIncidents', Incidents
Meteor.publish 'eventIncidents', (userEventId) ->
  Incidents.find({userEventId: userEventId})
Meteor.publish 'mapIncidents', () ->
  Incidents.find({locations: {$ne: null}}, {
    fields:
      userEventId: 1
      'dateRange.start': 1
      'dateRange.end': 1
      'dateRange.cumulative': 1
      locations: 1
      cases: 1
  })

# User Events
ReactiveTable.publish 'userEvents', UserEvents, {deleted: {$in: [null, false]}}
Meteor.publish 'userEvent', (eidID) ->
  UserEvents.find({_id: eidID})
Meteor.publish 'userEvents', () ->
  UserEvents.find({deleted: {$in: [null, false]}})

# Curator Sources
ReactiveTable.publish 'curatorSources', CuratorSources, {}
Meteor.publish 'curatorSources', (query) ->
  CuratorSources.find(query, {
    sort:
      publishDate: -1
  })

Meteor.publish 'eventArticles', (ueId) ->
  Articles.find({userEventId: ueId})

Meteor.publish 'articles', (query={}) ->
  Articles.find(query)

Meteor.publish 'feeds', ->
  Feeds.find()

# User status
Meteor.publish 'userStatus', () ->
  Meteor.users.find({'status.online': true }, {fields: {'status': 1 }})
