incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
articleSchema = require '/imports/schemas/article.coffee'
Articles = require '/imports/collections/articles.coffee'
PromedPosts = require '/imports/collections/promedPosts.coffee'

Meteor.startup ->
  incidents = Incidents.find().fetch()
  for incident in incidents
    try
      incidentReportSchema.validate(incident)
    catch error
      console.log error
      console.log JSON.stringify(incident, 0, 2)
  for article in Articles.find().fetch()
    promedId = /promedmail\.org\/post\/(\d+)$/ig.exec(article.url)?[1]
    if promedId
      post = PromedPosts.findOne(
        promedId: promedId
      )
      article.publishDate = post.promedDate
      # Aproximate DST for New York timezone
      daylightSavings = moment.utc(
        post.promedDate.getUTCFullYear() + "-03-08") <= post.promedDate
      daylightSavings = daylightSavings and moment.utc(
        post.promedDate.getUTCFullYear() + "-11-01") >= post.promedDate
      article.publishDateTZ = if daylightSavings then "EDT" else "EST"
      Articles.update(article._id, $set: article)
      try
        articleSchema.validate(article)
      catch error
        console.log error
        console.log JSON.stringify(article, 0, 2)
    else
      console.log "non-ProMED Article:", article.url
