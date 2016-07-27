References = new Meteor.Collection "references"

@grid ?= {}
@grid.References = References

Events = ->
  @grid.Events
  
getReferences = (eidID) ->
  event = Events().findOne({eidID: eidID})
  allReferences = []
  _.each event.references, (value, key) ->
    allReferences = allReferences.concat(value)
  allReferences = _.uniq(allReferences)
  References.find({zoteroId: {"$in": allReferences}})
  
References.getReferences = getReferences

if Meteor.isServer
  Meteor.publish "references", (eidID) ->
    getReferences(eidID)