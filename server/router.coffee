UserEvents = require '/imports/collections/userEvents.coffee'
CuratorSources = require '/imports/collections/curatorSources.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
utils = require '/imports/utils.coffee'
fs = Npm.require('fs')
path = Npm.require('path')
{ annotateContent } = require('/imports/ui/annotation')

Router.route("/revision", {where: "server"})
.get ->
  fs.readFile path.join(process.env.PWD, 'revision.txt'), 'utf8', (err, data)=>
    if err
      console.log(err)
      @response.end("Error getting revision. Check the server log for details.")
    else
      @response.end(data)

Router.route("/api/geoannotatedDocuments", {where: "server"})
.get ->
  @response.setHeader('Content-Type', 'application/ejson')
  @response.statusCode = 200
  @response.end(EJSON.stringify(CuratorSources.find({
    reviewed: true
  }, {
    skip: parseInt(@request.query.skip or 0)
    limit: parseInt(@request.query.limit or 2)
  }).map((source)->
    annotations = Incidents.find(
      url: source.url
      accepted: true
    ).map((i)->
      textOffsets: i.annotations.location[0].textOffsets
      attributes: i.locations[0].id
    )
    source.annotatedContent = annotateContent(source.content, annotations, {tag: 'geo'})
    source
  )))

# Router.route("/api/incidents", {where: "server"})
# .get ->
#   @response.setHeader('Content-Type', 'application/ejson')
#   @response.statusCode = 200
#   @response.end(EJSON.stringify(Incidents.find({}, {
#     skip: parseInt(@request.query.skip or 0)
#     limit: parseInt(@request.query.limit or 100)
#   }).fetch()))

# Router.route("/api/articles", {where: "server"})
# .get ->
#   @response.setHeader('Content-Type', 'application/ejson')
#   @response.statusCode = 200
#   @response.end(EJSON.stringify(Articles.find({}, {
#     skip: parseInt(@request.query.skip or 0)
#     limit: parseInt(@request.query.limit or 100)
#   }).fetch()))

# Router.route("/api/event-search/:name", {where: "server"})
# .get ->
#   pattern = '.*' + @params.name + '.*'
#   regex = new RegExp(pattern, 'g')
#   mongoProjection = {
#     eventName: {
#       $regex: regex,
#       $options: 'i'
#     }
#     deleted: {$in: [null, false]}
#   }
#   matchingEvents = UserEvents.find(mongoProjection, {sort: {eventName: 1}}).fetch()
 
#   @response.setHeader('Access-Control-Allow-Origin', '*')
#   @response.statusCode = 200
#   @response.end(JSON.stringify(matchingEvents))

# Router.route("/api/event-article", {where: "server"})
# .post ->
#   userEventId = @request.body.eventId ? ""
#   article = @request.body.articleUrl ? ""
  
#   if userEventId.length and article.length
#     userEvent = getUserEvents().findOne(userEventId)
#     if userEvent
#       existingArticle = Articles.find({url: article, userEventId: userEventId}).fetch()
      
#       if existingArticle.length is 0
#         Articles.insert({userEventId: userEventId, url: article})
  
#   @response.setHeader('Access-Control-Allow-Origin', '*')
#   @response.statusCode = 200
#   @response.end("")

# Router.route("/api/events-with-source", {where: "server"})
# .get ->
#   sanitizedUrl = @request.query.url.replace(/^https?:\/\//, "").replace(/^www\./, "")
#   articles = Articles.find(
#     url:
#       $regex: utils.regexEscape(sanitizedUrl) + "$"
#     deleted:
#       $in: [null, false]
#   ).fetch()
#   events = UserEvents.find(
#     _id:
#       $in: _.pluck(articles, 'userEventId')
#     deleted:
#       $in: [null, false]
#     displayOnPromed: true
#   ).map (event)->
#     event.articles = Articles.find(
#       userEventId: event._id
#     ).fetch()
#     event
#   console.log sanitizedUrl, events.length
#   @response.setHeader('Access-Control-Allow-Origin', '*')
#   @response.statusCode = 200
#   @response.end(JSON.stringify(events))
