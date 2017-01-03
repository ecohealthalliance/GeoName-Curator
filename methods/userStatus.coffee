Meteor.methods
  updateCuratorUserStatus: (sourceId) ->
    Meteor.users.update Meteor.userId(),
      $set:
        'status.curatorInboxSourceId': sourceId
