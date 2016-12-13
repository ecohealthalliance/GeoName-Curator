Incidents = require '/imports/collections/incidentReports.coffee'
UserEvents = require '/imports/collections/userEvents.coffee'
UserEventSchema = require '/imports/schemas/userEvent.coffee'

Meteor.methods
  upsertUserEvent: (userEvent) ->
    if not Roles.userIsInRole(@userId, ['admin'])
      throw new Meteor.Error("auth", "Admin level permissions are required for this action.")
    user = Meteor.user()
    now = new Date()
    userEvent = _.extend(userEvent, 
      lastModifiedDate: now
      lastModifiedByUserId: user._id
      lastModifiedByUserName: user.profile.name
    )
    UserEventSchema.validate(userEvent)
    UserEvents.upsert userEvent._id,
      $set: userEvent
      $setOnInsert:
        creationDate: now
        createdByUserId: user._id
        createdByUserName: user.profile.name
        articleCount: 0

  deleteUserEvent: (id) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      UserEvents.remove(id)

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
