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
          # format of date string is m/d/yyyy
          dateSplit = publishDate.split("/")
          # months are 0 indexed, so subtract 1 when creating the date
          insertArticle.publishDate = new Date(dateSplit[2], dateSplit[0] - 1, dateSplit[1])
        
        Articles.insert(insertArticle)
        
        Meteor.call("updateUserEventLastModified", eventId)