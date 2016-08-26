DateRegEx = /<span class="blue">Published Date:<\/span> ([^<]+)/

Meteor.methods
  getArticleLocations: (url) ->
    geonameIds = []
    result = HTTP.call("POST", "http://grits.eha.io:80/api/v1/public_diagnose",{
      params: { api_key: "grits28754", url: url }
    })
    if result.data and result.data.features
      for object in result.data.features
        if object.geoname
          geonameIds.push(object.geoname.geonameid.toString())
    unless geonameIds.length
      return []
    geonames = HTTP.get("https://geoname-lookup.eha.io/api/geonames", {
      params:
        ids: geonameIds
    })
    geonames.data.docs.map (loc) ->
      geonameId: loc.id
      name: loc.name
      displayName: loc.name
      subdivision: loc.admin1Name
      latitude: parseFloat(loc.latitude)
      longitude: parseFloat(loc.longitude)
      countryName: loc.countryName

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
