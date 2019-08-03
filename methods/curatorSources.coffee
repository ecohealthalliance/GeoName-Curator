CuratorSources = require '/imports/collections/curatorSources.coffee'

Meteor.methods
  markSourceReviewed: (id, reviewed) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      CuratorSources.update _id: id,
        $set:
          reviewed: reviewed
          reviewedDate: if reviewed then new Date() else null
          reviewedBy: if reviewed then Meteor.userId() else null

  startReview: (id) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      CuratorSources.update _id: id,
        $set:
          reviewStart: new Date
          reviewStartedBy: Meteor.userId()

  startQC: (id) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      CuratorSources.update _id: id,
        $set:
          QCStart: new Date
          QCStartedBy: Meteor.userId()

  markSourceQCed: (id, QCed) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      CuratorSources.update _id: id,
        $set:
          QCEnd: if QCed then new Date() else null
          QCedBy: if QCed then Meteor.userId() else null
