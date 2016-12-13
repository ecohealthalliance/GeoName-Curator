Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'

Meteor.methods
  editUserEvent: (id, name, summary, disease) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      user = Meteor.user()
      now = new Date()
      trimmedName = name.trim()

      if trimmedName.length
        UserEvents.upsert id,
          $set:
            eventName: trimmedName
            summary: summary
            disease: disease
            lastModifiedDate: now
            lastModifiedByUserId: user._id
            lastModifiedByUserName: user.profile.name
          $setOnInsert:
            creationDate: now
            createdByUserId: user._id
            createdByUserName: user.profile.name
            articleCount: 0

  deleteUserEvent: (id) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      UserEvents.update id,
        $set:
          deleted: true,
          deletedDate: new Date()

  editUserEventLastModified: (id) ->
    user = Meteor.user()
    if user
      UserEvents.update id,
        $set:
          lastModifiedDate: new Date(),
          lastModifiedByUserId: user._id,
          lastModifiedByUserName: user.profile.name

  editUserEventArticleCount: (id, countModifier) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      event = UserEvents.findOne(id)
      UserEvents.update id,
        $set:
          articleCount: event.articleCount + countModifier

  editUserEventLastIncidentDate: (id) ->
    event = UserEvents.findOne(id)
    latestEventIncident = Incidents.findOne
      userEventId: event._id
      {sort: addedDate: -1}
    if latestEventIncident
      UserEvents.update id,
        $set:
          lastIncidentDate: latestEventIncident.dateRange.end
    else
      UserEvents.update id,
        $unset:
          lastIncidentDate: ''
