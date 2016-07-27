Comments = new Meteor.Collection "comments"

@grid ?= {}
@grid.Comments = Comments

if Meteor.isServer
  Meteor.publish "adminComments", ->
    if Roles.userIsInRole(this.userId, ['admin'])
      Comments.find()
    else
      this.ready()

  Comments.allow
    insert: (userID, doc) ->
      doc.timeStamp = new Date()
      doc.userID = Meteor.user()._id

    remove: (userId, comment) ->
      Roles.userIsInRole(userId, ["admin"])
