DateRegEx = /<span class="blue">Published Date:<\/span> ([^<]+)/

GRITS_API_URL = process.env.GRITS_API_URL or "https://grits.eha.io/api/v1"
SPA_API_URL = process.env.SPA_API_URL or "http://spa.eha.io/api/v1"

Meteor.methods
  getArticleEnhancements: (url) ->
    check url, String
    geonameIds = []
    console.log "Calling GRITS API @ " + GRITS_API_URL
    result = HTTP.post(GRITS_API_URL + "/public_diagnose", {
      params:
        api_key: "Cr9LPAtL"
        returnSourceContent: true
        showKeypoints: true
        url: url
    })
    if result.data.error
      throw new Meteor.Error("grits-error", result.data.error)
    return result.data

  retrieveProMedArticleDate: _.memoize (articleId) ->
    check articleId, Number
    result = HTTP.call "GET", "http://www.promedmail.org/ajax/getPost.php",
      params:
        alert_id: articleId
      headers:
        Referer: "http://www.promedmail.org/"
    if result.statusCode is 200
      post = JSON.parse(result.content).post
      match = DateRegEx.exec(post)
      if match
        date = moment(match[1])
        tz = if date.isDST() then 'EDT' else 'EST'
        offset = UTCOffsets[tz]
        dateUTC = match[1].replace(' ', 'T') + offset
        dateUTC

  queryForSuggestedArticles: (eventId) ->
    check eventId, String
    event = UserEvents.findOne(eventId)
    console.log event
    console.log "Calling SPA API @ " + SPA_API_URL
    unless event
      throw new Meteor.Error 404, "Unable to fetch the requested event record"
    # Construct an array of keywords out of the event's name
    keywords = _.uniq event.eventName.match(/\w{3,}/g)
    # Build the mongodb query
    mongoQuery = { $and: [] }
    pushKeyword = (keyword) ->
      mongoQuery.$and.push
        content: { $regex: keyword, $options: 'i' }
    # Construct a query out of keywords
    for keyword in keywords
      pushKeyword(keyword)
    # Add the disease name from the event to the keywords
    if event.disease
      pushKeyword(event.disease)
    # Filter out related event sources
    notOneOfThese = []
    Articles.find(userEventId: eventId).forEach (relatedEventSource) ->
      url = relatedEventSource.url?[0]
      if url
        notOneOfThese.push url.match(/\d+/)?[0]
    if notOneOfThese.length
      mongoQuery.$and.push promedId: $nin: notOneOfThese
    # Query the remote server API
    response = HTTP.call('GET', "#{SPA_API_URL}/find", {
      params: { q: JSON.stringify(mongoQuery) }
    })
    if response
      response.data
    else
      throw new Meteor.Error 500, "Unable to reach the API"
