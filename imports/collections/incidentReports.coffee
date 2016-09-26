Incidents = new Meteor.Collection "counts"
Incidents.allow
insert: (userID, doc) ->
  doc.creationDate = new Date()
  Roles.userIsInRole(Meteor.userId(), ['admin'])
remove: (userID, doc) ->
  Roles.userIsInRole(Meteor.userId(), ['admin'])
module.exports = Incidents
