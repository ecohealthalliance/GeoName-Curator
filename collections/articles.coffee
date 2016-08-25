Articles = new Meteor.Collection "articles"

@grid ?= {}
@grid.Articles = Articles

getEventArticles = (userEventId) ->
  Articles.find({userEventId: userEventId})

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
  WGT:  '-0300'

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
  addEventArticle: (eventId, url, publishDate, publishDateTZ) ->
    if url.length
      insertArticle = {
        url: url,
        userEventId: eventId
      }
      existingArticle = Articles.find(insertArticle).fetch()
      unless existingArticle.length is 0
        throw new Meteor.Error(501, 'This article has already been added')
      else
        user = Meteor.user()
        insertArticle.addedByUserId = user._id
        insertArticle.addedByUserName = user.profile.name
        insertArticle.addedDate = new Date()
        if publishDate.length
          # Convert the input string into a Date object
          dateString = new Date(publishDate).toString()
          # Fix the timezone offset
          dateStringMatch = dateString.match(/(.*GMT)/)
          dateString = dateStringMatch[1] + UTCOffsets[publishDateTZ]
          insertArticle.publishDate = new Date(dateString)
        newId = Articles.insert(insertArticle)
        Meteor.call("updateUserEventLastModified", eventId)
        return newId
  removeEventArticle: (id) ->
    if Meteor.user()
      removed = Articles.findOne(id)
      Articles.remove(id)
      Meteor.call("removeOrphanedLocations", removed.userEventId, id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
