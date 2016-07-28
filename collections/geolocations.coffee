Geolocations = new Mongo.Collection "geolocations"

@grid ?= {}
@grid.Geolocations = Geolocations

if Meteor.isServer
  Meteor.publish "geolocations", () ->
    Geolocations.find({})
  Meteor.publish "eventLocations", (userEventId) ->
    Geolocations.find({userEventId: userEventId})

Meteor.methods
  generateGeonamesUrl: (geonameId) ->
    return "http://www.geonames.org/" + geonameId
  addEventLocations: (eventId, locations) ->
    if Meteor.user()
      existingLocations = []
      for loc in Geolocations.find({userEventId: eventId}).fetch()
        existingLocations.push(loc.geonameId)
      
      for location in locations
        if existingLocations.indexOf(location.geonameId.toString()) is -1
          geolocation = {
            userEventId: eventId,
            geonameId: location.geonameId,
            name: location.name,
            displayName: location.displayName,
            subdivision: location.subdivision,
            countryName: location.countryName,
            latitude: location.latitude,
            longitude: location.longitude,
            url: Meteor.call("generateGeonamesUrl", location.geonameId)
          }
          Geolocations.insert(geolocation)
    else
        throw new Meteor.Error(403, "Not authorized")
  removeEventLocation: (id) ->
    if Meteor.user()
      Geolocations.remove(id)
    else
        throw new Meteor.Error(403, "Not authorized")