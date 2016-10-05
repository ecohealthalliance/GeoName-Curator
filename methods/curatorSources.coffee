CuratorSources = require '/imports/collections/curatorSources.coffee'

Meteor.methods
  curateSource: (id, accepted) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      if accepted
        CuratorSources.update({_id: id}, {$set: {reviewed: true}})
