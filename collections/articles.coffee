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
          insertArticle.publishDate = moment(publishDate, "M/D/YYYY").toDate()

        newId = Articles.insert(insertArticle)

        Meteor.call("updateUserEventLastModified", eventId)

        return newId
  removeEventArticle: (id) ->
    if Meteor.user()
      removed = Articles.findOne(id)
      Articles.remove(id)
      Meteor.call("removeOrphanedLocations", removed.userEventId, id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
