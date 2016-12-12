incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
articleSchema = require '/imports/schemas/article.coffee'
Articles = require '/imports/collections/articles.coffee'
PromedPosts = require '/imports/collections/promedPosts.coffee'
CuratorSources = require '/imports/collections/curatorSources'

Meteor.startup ->
  # set incident dates
  incidents = Incidents.find().fetch()
  for incident in incidents
    try
      incidentReportSchema.validate(incident)
    catch error
      console.log error
      console.log JSON.stringify(incident, 0, 2)

  CuratorSources.update
    reviewed:
      $exists: false
    {$set: reviewed: false}
    {multi: true}

  # Clean-up curatorInboxSourceId when user goes offline
  Meteor.users.find({'status.online': true}).observe
    removed: (user) ->
      Meteor.users.update(user._id, {$set : {'status.curatorInboxSourceId': null}})
