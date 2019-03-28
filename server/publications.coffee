Incidents = require '/imports/collections/incidentReports.coffee'
SmartEvents = require '/imports/collections/smartEvents.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'
#Articles = require '/imports/collections/articles.coffee'
Feeds = require '/imports/collections/feeds.coffee'

# Incidents
ReactiveTable.publish 'curatorEventIncidents', Incidents, {deleted: {$in: [null, false]}}

# Curator Sources
ReactiveTable.publish 'curatorSources', CuratorSources, {}
Meteor.publish 'curatorSources', (query) ->
  CuratorSources.find(query)

Meteor.publish 'curatorSourceIncidentReports', (sourceId) ->
  Incidents.find {url: $regex: new RegExp("#{sourceId}$")},
    sort: 'annotations.case.0.textOffsets.0': 1

Meteor.publish 'feeds', ->
  Feeds.find()

# User status
Meteor.publish 'userStatus', () ->
  Meteor.users.find({'status.online': true }, {fields: {'status': 1 }})
