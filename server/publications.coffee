Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'

# Incidents
ReactiveTable.publish "curatorEventIncidents", Incidents
Meteor.publish "eventIncidents", (userEventId) ->
  Incidents.find({userEventId: userEventId})
Meteor.publish "mapIncidents", () ->
  Incidents.find({locations: {$ne: null}}, {
    fields:
      userEventId: 1
      "dateRange.start": 1
      "dateRange.end": 1
      "dateRange.cumulative": 1
      locations: 1
  })

# User Events
ReactiveTable.publish "userEvents", UserEvents, {}
Meteor.publish "userEvent", (eidID) ->
  UserEvents.find({_id: eidID})
Meteor.publish "userEvents", () ->
  UserEvents.find()

# Curator Sources
ReactiveTable.publish "curatorSources", CuratorSources, {}
Meteor.publish "curatorSources", (limit, range) ->
  query = {addedDate: {$exists: true}}
  if range and range.startDate and range.endDate
    query = {
      addedDate: {
        $gte: new Date(range.startDate)
        $lte: new Date(range.endDate)
      }
    }
  CuratorSources.find(query, {
    sort: {addedDate: -1}
    limit: limit || 100
  })