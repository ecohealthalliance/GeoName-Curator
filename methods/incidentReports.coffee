incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'
Constants = require '/imports/constants.coffee'

# A annotation's territory is the sentence containing it,
# and all the following sentences until the next annotation.
# Annotations in the same sentence are grouped.
getTerritories = (annotationsWithOffsets, sents) ->
  # Split annotations with multiple offsets
  # and sort by offset.
  annotationsWithSingleOffsets = []
  annotationsWithOffsets.forEach (annotation)->
    annotation.textOffsets.forEach (textOffset)->
      splitAnnotation = Object.create(annotation)
      splitAnnotation.textOffsets = [textOffset]
      annotationsWithSingleOffsets.push(splitAnnotation)
  annotationsWithOffsets = _.sortBy(annotationsWithSingleOffsets, (annotation)->
    annotation.textOffsets[0][0]
  )
  annotationIdx = 0
  sentStart = 0
  sentEnd = 0
  territories = []
  sents.forEach (sent) ->
    sentStart = sentEnd
    sentEnd = sentEnd + sent.length
    sentAnnotations = []
    while annotation = annotationsWithOffsets[annotationIdx]
      [aStart, aEnd] = annotation.textOffsets[0]
      if aStart > sentEnd
        break
      else
        sentAnnotations.push annotation
        annotationIdx++
    if sentAnnotations.length > 0 or territories.length == 0
      territories.push
        annotations: sentAnnotations
        territoryStart: sentStart
        territoryEnd: sentEnd
    else
      territories[territories.length - 1].territoryEnd = sentEnd
  return territories

# Parse text into an array of sentences separated by
# periods, colons, semi-colons, or double linebreaks.
parseSents = (text)->
  idx = 0
  sents = []
  sentStart = 0
  while idx < text.length
    char = text[idx]
    if char == '\n'
      [match] = text.slice(idx).match(/^\n+/)
      idx += match.length
      if match.length > 1
        sents[sents.length] = text.slice(sentStart, idx)
        sentStart = idx
    else if /^[\.\;\:]/.test(char)
      idx++
      sents[sents.length] = text.slice(sentStart, idx)
      sentStart = idx
    else
      idx++
  if sentStart < idx
    sents[sents.length] = text.slice(sentStart, idx)
  return sents


Meteor.methods
  addIncidentReport: (incident) ->
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to create incident reports")
    incident.addedByUserId = user._id
    incident.addedByUserName = user.profile.name
    incident.addedDate = new Date()
    newId = Incidents.insert(incident)
    # Meteor.call("editUserEventLastModified", incident.userEventId)
    # Meteor.call("editUserEventLastIncidentDate", incident.userEventId)
    return newId

  editIncidentReport: (incident) ->
    incidentReportSchema.validate(incident)
    user = Meteor.user()
    if not Roles.userIsInRole(user._id, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    res = Incidents.update(incident._id, incident)
    Meteor.call("editUserEventLastModified", incident.userEventId)
    Meteor.call("editUserEventLastIncidentDate", incident.userEventId)
    return incident._id

  addIncidentReports: (incidents) ->
    incidents.map (incident)->
      Meteor.call("addIncidentReport", incident)

  removeIncidentReport: (id) ->
    if not Roles.userIsInRole(@userId, ['admin'])
      throw new Meteor.Error("auth", "User does not have permission to edit incident reports")
    incident = Incidents.findOne(id)
    Incidents.update id,
      $set:
        deleted: true,
        deletedDate: new Date()
    Meteor.call("editUserEventLastModified", incident.userEventId)
    Meteor.call("editUserEventLastIncidentDate", incident.userEventId)

  addIncidentReportsFromEnhancement: (enhancements, article, collection, acceptByDefault) ->
    features = enhancements.features
    locationAnnotations = features.filter (f) -> f.type == 'location'
    datetimeAnnotations = features.filter (f) -> f.type == 'datetime'
    diseaseAnnotations = features.filter (f) -> f.type == 'diseases'
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
          publishMoment = moment.utc(article.publishDate)
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
        # Use the article's date as the default
        incident.dateRange =
          start: article.publishDate
          end: moment(article.publishDate).add(1, 'day')
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
        incident.url = [article.url]
        # The disease field is set to the last disease mentioned,
        # document classification, or event disease with overides in that order.
        event = UserEvents.findOne(article?.userEventId)
        if event?.disease
          incident.disease = event.disease
        enhancements.diseases.forEach ({name})->
          incident.disease = name
        diseaseTerritory.annotations.forEach ({value})->
          incident.disease = value
        incident.suggestedFields = _.intersection(
          Object.keys(incident),
          [
            'disease'
            'cases'
            'deaths'
            'dateRange'
            'status'
            if incident.locations.length then 'locations'
          ]
        )
        if incident.dateRange?.cumulative
          incident.suggestedFields.push('cumulative')
        if collection
          collection.insert(incident)
        else
          _incident = _.pick(incident, incidentReportSchema.objectKeys())
          Meteor.call('addIncidentReport', _incident)
      enhancements.source.cleanContent.content
