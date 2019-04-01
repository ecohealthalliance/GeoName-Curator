CuratorSources = require '/imports/collections/curatorSources.coffee'

Meteor.methods
  markSourceReviewed: (id, reviewed) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      CuratorSources.update _id: id,
        $set:
          reviewed: reviewed
          reviewedDate: if reviewed then new Date() else null
          reviewedBy: if reviewed then Meteor.userId() else null

  updateSourceEnhancements: (id, enhancements) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      CuratorSources.update _id: id,
        $set:
          enhancements: enhancements
