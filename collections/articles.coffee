Articles = new Meteor.Collection "articles"

@grid ?= {}
@grid.Articles = Articles
  
getEventArticles = (userEventId) ->
  Articles.find({userEventId: userEventId})
  
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
  addEventArticle: (eventId, url, publishDate) ->
    if url.length
      insertArticle = {
        url: url,
        userEventId: eventId
      }
      existingArticle = Articles.find(insertArticle).fetch()
      if existingArticle.length is 0
        user = Meteor.user()
        insertArticle.addedByUserId = user._id
        insertArticle.addedByUserName = user.profile.name
        insertArticle.addedDate = new Date()
        
        if publishDate.length
          # format of date string is yyyy-mm-dd
          insertArticle.publishDate = new Date(publishDate.split("-"))
        
        Articles.insert(insertArticle)
        
        Meteor.call("updateUserEventLastModified", eventId)