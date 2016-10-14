UserEvents = require '/imports/collections/userEvents.coffee'
Articles = require '/imports/collections/articles.coffee'

Router.route("/event-search/:name", {where: "server"})
.get ->
  pattern = '.*' + @params.name + '.*'
  regex = new RegExp(pattern, 'g')
  mongoProjection = {
    eventName: {
      $regex: regex,
      $options: 'i'
    }
  }
  matchingEvents = UserEvents.find(mongoProjection, {sort: {eventName: 1}}).fetch()
 
  @response.setHeader('Access-Control-Allow-Origin', '*')
  @response.statusCode = 200
  @response.end(JSON.stringify(matchingEvents))

Router.route("/event-article", {where: "server"})
.post ->
  userEventId = @request.body.eventId ? ""
  article = @request.body.articleUrl ? ""
  
  if userEventId.length and article.length
    userEvent = getUserEvents().findOne(userEventId)
    if userEvent
      existingArticle = Articles.find({url: article, userEventId: userEventId}).fetch()
      
      if existingArticle.length is 0
        Articles.insert({userEventId: userEventId, url: article})
  
  @response.setHeader('Access-Control-Allow-Origin', '*')
  @response.statusCode = 200
  @response.end("")

Router.route("/api/events-with-source", {where: "server"})
.get ->
  articles = Articles.find(
    url: @request.query.url
  ).fetch()
  events = UserEvents.find(
    _id:
      $in: _.pluck(articles, 'userEventId')
  ).map (event)->
    event.articles = Articles.find(
      userEventId: event._id
    ).fetch()
    event
  @response.setHeader('Access-Control-Allow-Origin', '*')
  @response.statusCode = 200
  @response.end(JSON.stringify(events))
