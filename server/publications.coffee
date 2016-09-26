Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'

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

ReactiveTable.publish "userEvents", UserEvents, {}
Meteor.publish "userEvent", (eidID) ->
  UserEvents.find({_id: eidID})
Meteor.publish "userEvents", () ->
  UserEvents.find()
