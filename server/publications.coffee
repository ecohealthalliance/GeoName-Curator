Incidents = require '/imports/collections/incidentReports.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'

# Incidents
ReactiveTable.publish 'curatorEventIncidents', Incidents, {deleted: {$in: [null, false]}}

# Curator Sources
ReactiveTable.publish 'curatorSources', CuratorSources, {}
Meteor.publish 'curatorSources', (query) ->
  CuratorSources.find(query)

Meteor.publish 'curatorSourceIncidentReports', (sourceId) ->
  Incidents.find {url: $regex: new RegExp("#{sourceId}$")},
    sort: 'annotations.case.0.textOffsets.0': 1

# User status
Meteor.publish 'userStatus', () ->
  Meteor.users.find({'status.online': true }, {fields: {'status': 1 }})

Meteor.publish "user", ->
  Meteor.users.find(_id: @userId)
