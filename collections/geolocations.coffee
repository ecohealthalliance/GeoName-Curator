Geolocations = new Mongo.Collection "geolocations"

@grid ?= {}
@grid.Geolocations = Geolocations

if Meteor.isServer
  Meteor.publish "geolocations", () ->
    Geolocations.find({})
  Meteor.publish "eventLocations", (userEventId) ->
    Geolocations.find({userEventId: userEventId})

Meteor.methods
  addEventLocations: (eventId, articles, locations) ->
    if Meteor.user()
      existingLocations = []

      for loc in Geolocations.find({userEventId: eventId}).fetch()
        existingLocations.push(loc.geonameId)

      for article, index in articles
        articles[index].index = index+1

      for location in locations
        if existingLocations.indexOf(location.geonameId.toString()) is -1
          user = Meteor.user()
          geolocation = {
            userEventId: eventId,
            geonameId: location.geonameId,
            name: location.name,
            displayName: location.displayName,
            subdivision: location.subdivision,
            countryName: location.countryName,
            latitude: location.latitude,
            longitude: location.longitude,
            addedByUserId: user._id,
            addedByUserName: user.profile.name,
            addedDate: new Date()
            sourceArticles: articles
          }
          Geolocations.insert(geolocation)

          Meteor.call("updateUserEventLastModified", eventId)
    else
        throw new Meteor.Error(403, "Not authorized")
  removeEventLocation: (id) ->
    if Meteor.user()
      Geolocations.remove(id)
    else
      throw new Meteor.Error(403, "Not authorized")
  updateLocationArticles: (id, articles) ->
    if Meteor.user()
      location = Geolocations.findOne(id)

      if location
        for article, index in articles
          articles[index].index = index+1

        Geolocations.update(id, {$set: {
          sourceArticles: articles
        }})

        Meteor.call("updateUserEventLastModified", location.userEventId)
    else
      throw new Meteor.Error(403, "Not authorized")
  removeOrphanedLocations: (eventId, articleId) ->
    Geolocations.remove({
      userEventId: eventId,
      "sourceArticles.articleId": articleId,
      sourceArticles: {$size: 1}
    })
    Geolocations.update(
      {
        userEventId: eventId
      },
      {
        $pull: {
          sourceArticles: {articleId: articleId}
        }
      },
      {multi: true}
    )


# Convert Geolocation records into Counts
if Meteor.isServer
  Meteor.startup ->
    # Loop through geolocations in the database
    Geolocations.find({imported: $ne: true}).forEach (geolocation) ->
      newIncidentReport =
        addedByUserId: geolocation.addedByUserId
        addedByUserName: geolocation.addedByUserName
        addedDate: geolocation.addedDate
        specify: 'Location Import'
        date: null
        locations: [
          countryName: geolocation.countryName
          displayName: geolocation.displayName
          geonameId: geolocation.geonameId
          latitude: geolocation.latitude
          longitude: geolocation.longitude
          name: geolocation.name
          subdivision: geolocation.subdivision
        ]
        url: [ geolocation.sourceArticles[0].url ]
        userEventId: geolocation.userEventId
      # Insert the newly created Count
      Counts.insert newIncidentReport
      # Remove the original record from the database
      Geolocations.update(geolocation._id, $set: imported: true)
