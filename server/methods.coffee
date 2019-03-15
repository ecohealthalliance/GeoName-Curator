Articles = require '/imports/collections/articles.coffee'
Constants = require '/imports/constants.coffee'
Incidents = require '/imports/collections/incidentReports'
SmartEvents = require '/imports/collections/smartEvents'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
import { formatUrl, cleanUrl, createIncidentReportsFromEnhancements, regexEscape } from '/imports/utils.coffee'

DateRegEx = /<span class="blue">Published Date:<\/span> ([^<]+)/

Meteor.methods
  getArticleEnhancements: (article) ->
    @unblock()
    check article.url, Match.Maybe(String)
    check article.content, Match.Maybe(String)
    check article.publishDate, Match.Maybe(Date)
    check article.addedDate, Match.Maybe(Date)
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
    console.log "success"
    enhancements = result.data
    # Normalize geoname data in GRITS annotations to match incident report schema.
    # The geoname lookup service is queried to get admin names.
    # The GRITS api reponse only includes admin codes at the moment.
    geonameIds = []
    features = enhancements.features
    locationAnnotations = features.filter (f) -> f.type == 'location'
    geonameIds = locationAnnotations.map((r) -> r.geoname.geonameid)
    if geonameIds.length > 0
      geonamesResult = HTTP.get Constants.GRITS_URL + '/api/geoname_lookup/api/geonames', {
        params:
          ids: geonameIds
      }
      geonames = geonamesResult.data.docs
      geonamesById = {}
      geonames.forEach (geoname) ->
        if not geoname
          # null geonames are probably a bug in the geoname lookup service
          return
        geonamesById[geoname.id] =
          id: geoname.id
          name: geoname.name
          admin1Name: geoname.admin1Name
          admin2Name: geoname.admin2Name
          latitude: parseFloat(geoname.latitude)
          longitude: parseFloat(geoname.longitude)
          countryName: geoname.countryName
          population: geoname.population
          featureClass: geoname.featureClass
          featureCode: geoname.featureCode
          alternateNames: geoname.alternateNames
      locationAnnotations = locationAnnotations.filter (loc)->
        geoname = geonamesById[loc.geoname.geonameid]
        if geoname
          loc.geoname = geoname
          true
        else
          false
    return enhancements

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

  addSourceIncidentReportsToCollection: (source, options) ->
    { acceptByDefault } = options
    enhancements = source.enhancements
    check enhancements, Object
    options.url = cleanUrl(source.url)
    options.publishDate = source.publishDate
    incidents = createIncidentReportsFromEnhancements(enhancements, options)
    incidents = incidents.map (incident) ->
      incident = _.pick(incident, incidentReportSchema.objectKeys())
    # check for unexpected urls
    if not options.url.startsWith("promedmail.org/post/")
      throw Meteor.Error("Bad url")
    # Remove prior unassociated incident reports for the article
    Incidents.remove(
      url: $regex: regexEscape(options.url) + "$"
      userEventId: $exists: false
      autogenerated: $ne: false
    )
    Meteor.call('addIncidentReports', incidents, false)
