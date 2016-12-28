Template.curatorUserStatus.onCreated ->
  @userStatusHandle = @subscribe('userStatus')
  @onlineUserCount = new ReactiveVar 0
  @autorun =>
    Meteor.call 'updateCuratorUserStatus', @data.selectedSourceId.get(), (err, res) =>
      if err
        toastr.error(err.message)

Template.curatorUserStatus.onRendered ->
  instance = @
  @autorun ->
    instance.onlineUserCount.get()
    Meteor.defer ->
      $('.curator-viewing-status').tooltip
        container: 'body'
        placement: 'bottom'

Template.curatorUserStatus.onDestroyed ->
  Meteor.call 'updateCuratorUserStatus', null, (err, res) =>
    if err
      toastr.error(err.message)

Template.curatorUserStatus.helpers
  hasOnlineUsers: ->
    instance = Template.instance()
    if instance.userStatusHandle.ready()
      # Count users currently viewing the selected source minus the current
      count = Meteor.users.find(
        'status.online': true
        'status.curatorInboxSourceId': instance.data.selectedSourceId.get()
      ).count() - 1
      instance.onlineUserCount.set(count)
      count
