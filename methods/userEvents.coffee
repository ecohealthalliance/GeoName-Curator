Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'

Meteor.methods
  addUserEvent: (name, summary) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      trimmedName = name.trim()
      user = Meteor.user()
      now = new Date()

      if trimmedName.length isnt 0
        UserEvents.insert(
          eventName: trimmedName
          summary: summary
          creationDate: now
          createdByUserId: user._id
          createdByUserName: user.profile.name
          lastModifiedDate: now
          lastModifiedByUserId: user._id
          lastModifiedByUserName: user.profile.name
          articleCount: 0
        )

  updateUserEvent: (id, name, summary, disease) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      user = Meteor.user()
      UserEvents.update(id, {$set: {
        eventName: name,
        summary: summary,
        disease: disease,
        lastModifiedDate: new Date(),
        lastModifiedByUserId: user._id,
        lastModifiedByUserName: user.profile.name
      }})
  deleteUserEvent: (id) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      UserEvents.remove(id)

  updateUserEventLastModified: (id) ->
    user = Meteor.user()
    if user
      UserEvents.update(id, {$set: {
        lastModifiedDate: new Date(),
        lastModifiedByUserId: user._id,
        lastModifiedByUserName: user.profile.name
      }})
  updateUserEventArticleCount: (id, countModifier) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      event = UserEvents.findOne(id)
      UserEvents.update(id, {$set: {articleCount: event.articleCount + countModifier}})
  updateUserEventLastIncidentDate: (id) ->
    event = UserEvents.findOne(id)
    latestEventIncident = Incidents.findOne({userEventId: event._id}, {sort: {addedDate: -1}})
    if latestEventIncident
      UserEvents.update(id, {
        $set:
          lastIncidentDate: latestEventIncident.dateRange.end
      })
    else
      UserEvents.update(id, {
        $unset:
          lastIncidentDate: ""
      })

if Meteor.isServer
    Meteor.methods
      searchUserEvents: (search) ->
        UserEvents.find({$text: {$search: search}}, {fields: {score: {$meta: 'textScore'}}, sort: {score: {$meta: 'textScore'}}}).fetch()
