
Meteor.methods
  updateCuratorUserStatus: (sourceId) ->
    user = Meteor.user()
    if user
      Meteor.users.update(user, {$set : {'status.curatorInboxSourceId': sourceId}})
      return true
    else
      return false
