Articles = require '/imports/collections/articles.coffee'

Meteor.methods
  addEventSource: (source) -> #eventId, url, publishDate, publishDateTZ
    user = Meteor.user()
    if user and Roles.userIsInRole(user._id, ['admin'])
      if source.url.length
        insertArticle = {
          url: source.url,
          title: source.title,
          userEventId: source.userEventId
        }
        existingArticle = Articles.find(insertArticle).fetch()
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
      removed = Articles.findOne(id)
      Articles.remove(id)
      Meteor.call("updateUserEventLastModified", removed.userEventId)
      Meteor.call("updateUserEventArticleCount", removed.userEventId, -1)
