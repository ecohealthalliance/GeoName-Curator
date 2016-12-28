Template.curatorUserStatus.onCreated ->
  @hasOnlineUsers = new ReactiveVar false
  @userStatusHandle = @subscribe('userStatus')
  @autorun =>
    Meteor.call 'updateCuratorUserStatus', @data.selectedSourceId.get(), (err, res) =>
      if err
        toastr.error(err.message)

Template.curatorUserStatus.onDestroyed ->
  Meteor.call 'updateCuratorUserStatus', null, (err, res) =>
    if err
      toastr.error(err.message)

userCount = (sourceId) ->
  Meteor.users.find({'status.online': true, 'status.curatorInboxSourceId': sourceId}).count() - 1

Template.curatorUserStatus.helpers
  hasOnlineUsers: () ->
    instance = Template.instance()
    if instance.userStatusHandle.ready()
      sourceId = instance.data.selectedSourceId.get()
      userCount(sourceId)

  usersOnlineCount: () ->
    instance = Template.instance()
    sourceId = instance.data.selectedSourceId.get()
    userCount(sourceId)

  usersOnlineMessage: () ->
    instance = Template.instance()
    sourceId = instance.data.selectedSourceId.get()
    count = userCount(sourceId)
    if count == 1
      return "There is #{count} other user viewing this source"
    if count > 1
      return "There are #{count} other users viewing this source"
