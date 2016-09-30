@Articles = new Meteor.Collection "articles"

@grid ?= {}
@grid.Articles = Articles

getEventArticles = (userEventId) ->
  grid.Articles.find({userEventId: userEventId})

@UTCOffsets =
  ADT:  '-0300'
  AKDT: '-0800'
  AKST: '-0900'
  AST:  '-0400'
  CDT:  '-0500'
  CST:  '-0600'
  EDT:  '-0400'
  EGST: '+0000'
  EGT:  '-0100'
  EST:  '-0500'
  HADT: '-0900'
  HAST: '-1000'
  MDT:  '-0600'
  MST:  '-0700'
  NDT:  '-0230'
  NST:  '-0330'
  PDT:  '-0700'
  PMDT: '-0200'
  PMST: '-0300'
  PST:  '-0800'
  WGST: '-0200'
  WGT: '-0300'

Articles.getEventArticles = getEventArticles

if Meteor.isServer
  Meteor.publish "eventArticles", (ueId) ->
    getEventArticles(ueId)

  Articles.allow
    insert: (userID, doc) ->
      return true
    remove: (userID, doc) ->
      return Meteor.user()

Meteor.methods
  addEventSource: (source) -> #eventId, url, publishDate, publishDateTZ
    user = Meteor.user()
    if user and Roles.userIsInRole(user._id, ['admin'])
      if source.url.length
        insertArticle = {
          url: source.url,
          userEventId: source.userEventId
        }
        existingArticle = grid.Articles.find(insertArticle).fetch()
        unless existingArticle.length is 0
          throw new Meteor.Error(501, 'This article has already been added')
        else
          insertArticle = source
          insertArticle.addedByUserId = user._id
          insertArticle.addedByUserName = user.profile.name
          insertArticle.addedDate = new Date()
          newId = Articles.insert(insertArticle)
          Meteor.call("updateUserEventLastModified", insertArticle.userEventId)
          Meteor.call("updateUserEventArticleCount", insertArticle.userEventId, 1)
          return newId
    else
      throw new Meteor.Error("auth", "User does not have permission to add source articles")

  updateEventSource: (source) ->
    user = Meteor.user()
    if user and Roles.userIsInRole(user._id, ['admin'])
      Articles.update(source._id, {$set: {publishDate: source.publishDate, publishDateTZ: source.publishDateTZ}})
      Meteor.call("updateUserEventLastModified", source.userEventId)
    else
      throw new Meteor.Error("auth", "User does not have permission to edit source articles")

  removeEventSource: (id) ->
    if Roles.userIsInRole(Meteor.userId(), ['admin'])
      removed = grid.Articles.findOne(id)
      Articles.remove(id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
      Meteor.call("updateUserEventArticleCount", removed.userEventId, -1)
