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