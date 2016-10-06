CuratorSources = require '/imports/collections/curatorSources.coffee'

Meteor.methods
  curateSource: (id, reviewed) ->
      if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
        CuratorSources.update({_id: id}, {
          $set:
            reviewed: reviewed
        })

  associateEventWithSource: (articleId, eventId) ->
    if CuratorSources.findOne( { _id: articleId, relatedEvents: eventId } )
      CuratorSources.update articleId, $pull:
        relatedEvents: eventId
    else
      CuratorSources.update articleId, $push:
        relatedEvents: eventId
