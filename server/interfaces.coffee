DateRegEx = /<span class="blue">Published Date:<\/span> ([^<]+)/

GRITS_API_URL = process.env.GRITS_API_URL or "https://grits.eha.io/api/v1"

Meteor.methods
  getArticleEnhancements: (url) ->
    geonameIds = []
    console.log "Calling GRITS API @ " + GRITS_API_URL
    result = HTTP.post(GRITS_API_URL + "/public_diagnose", {
      params:
        api_key: "grits28754"
        returnSourceContent: true
        showKeypoints: true
        url: url
    })
    if result.data.error
      throw new Meteor.Error("grits-error", result.data.error)
    return result.data

  retrieveProMedArticleDate: _.memoize( (articleID) ->
    result = HTTP.call "GET", "http://www.promedmail.org/ajax/getPost.php",
      params:
        alert_id: articleID
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
    )
