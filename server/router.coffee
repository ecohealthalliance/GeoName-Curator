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
  feedId = @request.query.feedId
  query = {
    reviewed: true
  }
  if feedId
    query.feedId = feedId
  @response.end(EJSON.stringify(CuratorSources.find(query, {
    skip: parseInt(@request.query.skip or 0)
    limit: parseInt(@request.query.limit or 10)
  }).map((source)->
    annotations = Incidents.find(
      url: $regex: utils.regexEscape('promedmail.org/post/' + source._sourceId) + "$"
      accepted: true
    ).map((i)->
      if i.locationNotFound
        i.ignore = true
      if not i.ignore and not i.locations[0]?.id
        return
      textOffsets: i.annotations.location[0].textOffsets
      tag: if i.ignore then 'ignore' else 'geo'
      attributes:
        id: if not i.ignore then i.locations[0].id
    ).filter (x) -> x
    source.annotatedContent = annotateContent(
      source.enhancements.source.cleanContent.content, annotations)
    source
  )))
