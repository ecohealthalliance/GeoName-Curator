UserEvents = require '/imports/collections/userEvents.coffee'
Articles = require '/imports/collections/articles.coffee'
PromedPosts = require '/imports/collections/promedPosts.coffee'
Constants = require '/imports/constants.coffee'
Incidents = require '/imports/collections/incidentReports'
SmartEvents = require '/imports/collections/smartEvents'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
import { formatUrl, parseSents, getTerritories } from '/imports/utils.coffee'

DateRegEx = /<span class="blue">Published Date:<\/span> ([^<]+)/

Meteor.methods
  getArticleEnhancements: (article) ->
    @unblock()
    check article.url, Match.Maybe(String)
    check article.content, Match.Maybe(String)
    check article.publishDate, Match.Maybe(Date)
    check article.addedDate, Match.Maybe(Date)
    geonameIds = []
    console.log "Calling GRITS API @ " + Constants.GRITS_URL
    params =
      api_key: Constants.GRITS_API_KEY
      returnSourceContent: true
    if article.publishDate or article.addedDate
      params.content_date = moment.utc(
        article.publishDate or article.addedDate
      ).utc().format("YYYY-MM-DDTHH:mm:ss")
    if article.content
      params.content = article.content
    else if article.url
      # formatUrl takes a database cleanUrl and adds 'http://'
      params.url = formatUrl(article.url)
    else
      Meteor.Error("InvalidArticle", "Content or a URL must be specified")
    result = HTTP.post(Constants.GRITS_URL + "/api/v1/public_diagnose", params: params)
    if result.data.error
      throw new Meteor.Error("grits-error", result.data.error)
    return result.data

  retrieveProMedArticle: (articleId) ->
    @unblock()
    article = PromedPosts.findOne
      promedId: "#{articleId}"

    promedDate: article.promedDate
    url: "http://www.promedmail.org/post/#{article.promedId}"
    subject: article.subject.raw

  queryForSuggestedArticles: (eventId) ->
    @unblock()
    check eventId, String
    event = UserEvents.findOne(eventId)
    console.log "Calling SPA API @ " + Constants.SPA_API_URL
    unless event
      throw new Meteor.Error 404, "Unable to fetch the requested event record"
    # Construct an array of keywords out of the event's name
    keywords = _.uniq event.eventName.match(/\w{3,}/g)
    # Add the disease name from the event to the keywords
    if event.disease
      keywords.push(event.disease)
    # Collect related event source ID's
    notOneOfThese = []
    Articles.find(userEventId: eventId).forEach (relatedEventSource) ->
      url = relatedEventSource.url
      if url
        notOneOfThese.push url.match(/\d+/)?[0]
    # Query the remote server API
    response = HTTP.call('GET', "#{Constants.SPA_API_URL}/search", {
      params: { text: keywords.join(' '), not: notOneOfThese.join(' ') }
    })
    if response
      response.data
    else
      throw new Meteor.Error 500, "Unable to reach the API"

  ###
  # searchUserEvents - perform a full-text search on `eventName` and `summary`,
  #   sorted by matching score.
  #
  # @param {string} search, the text to search for matches
  # @returns {array} userEvents, an array of userEvents
  ###
  searchUserEvents: (search) ->
    @unblock()
    UserEvents.find({
      $text:
        $search: search
      deleted: {$in: [null, false]}
    }, {
        fields:
          score:
            $meta: 'textScore'
        sort:
          score:
            $meta: 'textScore'
    }).fetch()

  ###
  # Create or update an EIDR-C meteor account for a BSVE user with the given
  # authentication info.
  # @param authInfo.authTicket - The BSVE authTicket used to verify the account
  #   with the BSVE. The EIDR-C user's password is set to the authTicket.
  # @param authInfo.user - The BSVE user's username. The EIDR-C username
  #   is the BSVE username with bsve- prepended.
  ###
  SetBSVEAuthTicketPassword: (authInfo)->
    # The api path chosen here is aribitrary, the call is only to verify that
    # the auth ticket works.
    response = HTTP.get("https://api.bsvecosystem.net/data/v2/sources/PON", {
      headers:
        "harbinger-auth-ticket": authInfo.authTicket
    })
    if Meteor.settings.private?.disableBSVEAuthentication
      throw new Meteor.Error("BSVEAuthFailure", "BSVE Authentication is disabled.")
    if response.data.status != 1
      throw new Meteor.Error("BSVEAuthFailure", response.data.message)
    meteorUser = Accounts.findUserByUsername("bsve-" + authInfo.user)
    if not meteorUser
      console.log "Creating user"
      {firstName, lastName} = authInfo.userData
      userId = Accounts.createUser(
        username: "bsve-" + authInfo.user
        profile:
          name: firstName + " " + lastName
      )
    else
      userId = meteorUser._id
    Roles.addUsersToRoles([userId], ['admin'])
    Accounts.setPassword(userId, authInfo.authTicket, logout:false)

  createIncidentReportsFromEnhancements: (options) ->
    { enhancements, source, acceptByDefault, addToCollection } = options
    incidents = []
    features = enhancements.features
    locationAnnotations = features.filter (f) -> f.type == 'location'
    datetimeAnnotations = features.filter (f) -> f.type == 'datetime'
    diseaseAnnotations = features.filter (f) ->
      f.type == 'resolvedKeyword' and f.resolutions.some((r)->
        # resolution is from the disease ontology
        r.uri.startsWith("http://purl.obolibrary.org/obo/DOID")
      )
    countAnnotations = features.filter (f) -> f.type == 'count'
    geonameIds = locationAnnotations.map((r) -> r.geoname.geonameid)
    # Query geoname lookup service to get admin names.
    # The GRITS api reponse only includes admin codes.
    new Promise((resolve, reject) =>
      if geonameIds.length == 0
        resolve([])
      else
        HTTP.get Constants.GRITS_URL + '/api/geoname_lookup/api/geonames', {
          params:
            ids: geonameIds
        }, (error, geonamesResult) =>
          if error
            toastr.error error.reason
            Modal.hide(@)
            reject()
          else
            resolve(geonamesResult.data.docs)
    ).then (locations) =>
      geonamesById = {}
      locations.forEach (loc) ->
        geonamesById[loc.id] =
          id: loc.id
          name: loc.name
          admin1Name: loc.admin1Name
          admin2Name: loc.admin2Name
          latitude: parseFloat(loc.latitude)
          longitude: parseFloat(loc.longitude)
          countryName: loc.countryName
          population: loc.population
          featureClass: loc.featureClass
          featureCode: loc.featureCode
          alternateNames: loc.alternateNames
      sents = parseSents(enhancements.source.cleanContent.content)
      locTerritories = getTerritories(locationAnnotations, sents)
      datetimeAnnotations = datetimeAnnotations
        .map (timeAnnotation) =>
          if not (timeAnnotation.timeRange and
            timeAnnotation.timeRange.begin and
            timeAnnotation.timeRange.end
          )
            return
          # moment parses 0 based month indecies
          if timeAnnotation.timeRange.begin.month
            timeAnnotation.timeRange.begin.month--
          if timeAnnotation.timeRange.end.month
            timeAnnotation.timeRange.end.month--
          timeAnnotation.precision = (
            Object.keys(timeAnnotation.timeRange.end).length +
            Object.keys(timeAnnotation.timeRange.end).length
          )
          timeAnnotation.beginMoment = moment.utc(
            timeAnnotation.timeRange.begin
          )
          # Round up the to day end
          timeAnnotation.endMoment = moment.utc(
            timeAnnotation.timeRange.end
          ).endOf('day')
          publishMoment = moment.utc(source.publishDate)
          if timeAnnotation.beginMoment.isAfter publishMoment, 'day'
            # Omit future dates
            return
          if timeAnnotation.endMoment.isAfter publishMoment, 'day'
            # Truncate ranges that extend into the future
            timeAnnotation.endMoment = publishMoment
          return timeAnnotation
        .filter (x) -> x
      dateTerritories = getTerritories(datetimeAnnotations, sents)
      diseaseTerritories = getTerritories(diseaseAnnotations, sents)
      countAnnotations.forEach (countAnnotation) =>
        [start, end] = countAnnotation.textOffsets[0]
        locationTerritory = _.find locTerritories, ({territoryStart, territoryEnd}) ->
          return (start <= territoryEnd and start >= territoryStart)
        dateTerritory = _.find dateTerritories, ({territoryStart, territoryEnd}) ->
          return (start <= territoryEnd and start >= territoryStart)
        diseaseTerritory = _.find diseaseTerritories, ({territoryStart, territoryEnd}) ->
          return (start <= territoryEnd and start >= territoryStart)
        incident =
          locations: locationTerritory.annotations.map(({geoname}) ->
            geonamesById[geoname.geonameid]
          )
        maxPrecision = 0
        # Use the source's date as the default
        incident.dateRange =
          start: source.publishDate
          end: moment(source.publishDate).add(1, 'day').toDate()
          type: 'day'
        dateTerritory.annotations.forEach (timeAnnotation)->
          if (timeAnnotation.precision > maxPrecision and
            timeAnnotation.beginMoment.isValid() and
            timeAnnotation.endMoment.isValid()
          )
            maxPrecision = timeAnnotation.precision
            incident.dateRange =
              start: timeAnnotation.beginMoment.toDate()
              end: timeAnnotation.endMoment.toDate()
            rangeHours = moment(incident.dateRange.end)
              .diff(incident.dateRange.start, 'hours')
            if rangeHours <= 24
              incident.dateRange.type = 'day'
            else
              incident.dateRange.type = 'precise'
        incident.dateTerritory = dateTerritory
        incident.locationTerritory = locationTerritory
        incident.diseaseTerritory = diseaseTerritory
        incident.countAnnotation = countAnnotation
        { count, attributes } = countAnnotation
        if 'death' in attributes
          incident.deaths = count
        else if "case" in attributes or "hospitalization" in attributes
          incident.cases = count
        else
          incident.cases = count
          incident.uncertainCountType = true
        if acceptByDefault and not incident.uncertainCountType
          incident.accepted = true
        # Detect whether count is cumulative
        if 'incremental' in attributes
          incident.dateRange.cumulative = false
        else if 'cumulative' in attributes
          incident.dateRange.cumulative = true
        else if incident.dateRange.type == 'day' and count > 300
          incident.dateRange.cumulative = true
        suspectedAttributes = _.intersection([
          'approximate', 'average', 'suspected'
        ], attributes)
        if suspectedAttributes.length > 0
          incident.status = 'suspected'
        incident.url = source.url
        # The disease field is set to the last disease mentioned.
        diseaseTerritory.annotations.forEach (annotation)->
          incident.resolvedDisease =
            id: annotation.resolutions[0].uri
            text: annotation.resolutions[0].label
        incident.suggestedFields = _.intersection(
          Object.keys(incident),
          [
            'resolvedDisease'
            'cases'
            'deaths'
            'dateRange'
            'status'
            if incident.locations.length then 'locations'
          ]
        )
        if incident.dateRange?.cumulative
          incident.suggestedFields.push('cumulative')

        annotations =
          case: [
            textOffsets: incident.countAnnotation.textOffsets[0]
            text: incident.countAnnotation.text
          ]
        if locationTerritory.annotations.length
          annotations.location =
            locationTerritory.annotations.map (a) -> textOffsets: a.textOffsets[0]
        if dateTerritory.annotations.length
          annotations.date =
            dateTerritory.annotations.map (a) -> textOffsets: a.textOffsets[0]
        if diseaseTerritory.annotations.length
          annotations.disease =
            diseaseTerritory.annotations.map (a) -> textOffsets: a.textOffsets[0]
        incident.annotations = annotations

        incidents.push(incident)

      incidentData =
        content: enhancements.source.cleanContent.content
        incidents: incidents

      if addToCollection
        _incidents = incidents.map (incident) ->
          _incident = _.pick(incident, incidentReportSchema.objectKeys())
        Meteor.call 'addIncidentReports', _incidents, false, (error, result) ->
          return incidentData

      else
        return incidentData
