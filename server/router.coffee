getEvents = =>
  @grid.Events

getUserEvents = =>
  @grid.UserEvents

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
  matchingEvents = getUserEvents().find(mongoProjection, {sort: {eventName: 1}}).fetch()
 
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
      existingArticle = grid.Articles.find({url: article, userEventId: userEventId}).fetch()
      
      if existingArticle.length is 0
        grid.Articles.insert({userEventId: userEventId, url: article})
  
  @response.setHeader('Access-Control-Allow-Origin', '*')
  @response.statusCode = 200
  @response.end("")

Router.route "/sitemap.xml", 
  where: 'server'
.get ->
  ROOT_URL = process.env.ROOT_URL or "//localhost/"
  if ROOT_URL.slice(-1) isnt "/"
    ROOT_URL += "/"
  @response.end """
  <?xml version="1.0" encoding="utf-8"?>
  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" 
     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
      #{getEvents().find({}).map((event) ->
        "<url><loc>#{ROOT_URL}event/#{event.eidID}</loc></url>"
      ).join("\n")}
  </urlset>
  """
