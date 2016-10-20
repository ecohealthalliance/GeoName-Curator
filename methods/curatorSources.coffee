CuratorSources = require '/imports/collections/curatorSources.coffee'

Meteor.methods
  curateSource: (id, reviewed) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      CuratorSources.update({_id: id}, {
        $set:
          reviewed: reviewed
      })
