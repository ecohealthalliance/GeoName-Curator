Incidents = require '/imports/collections/incidentReports.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'

# Curator Sources
ReactiveTable.publish 'curatorSources', CuratorSources, {}, {
  disablePageCountReactivity: true
  fields:
    title: 1
    reviewed: 1
    reviewedDate: 1
    feedId: 1
    'enhancements.diagnoserVersion': 1
}
Meteor.publish 'curatorSources', (query) ->
  CuratorSources.find(query, limit: 100)

Meteor.publish 'curatorSourceIncidentReports', (sourceId) ->
  Incidents.find {url: $regex: new RegExp("#{sourceId}$")},
    sort: 'annotations.case.0.textOffsets.0': 1
    limit: 10000

Meteor.publish 'userProfilesForSource', (sourceId)->
  if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin']) and sourceId
    source = CuratorSources.findOne(_id: sourceId)
    Meteor.users.find(
      _id:
        $in: [source.QCedBy, source.reviewedBy, source.reviewStartedBy, source.QCStartedBy]
    , {fields: profile: 1})

# User status
Meteor.publish 'userStatus', () ->
  Meteor.users.find({'status.online': true }, {fields: {'status': 1 }})

Meteor.publish "user", ->
  Meteor.users.find(_id: @userId)
