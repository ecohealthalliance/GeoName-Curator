
@PromedArticles = new Meteor.Collection "promed_articles"

if Meteor.isServer
  ReactiveTable.publish "promedArticles", PromedArticles, {}

  Meteor.publish "promedArticles", (limit, range) ->
    query = {addedDate: {$exists: true}}
    if range and range.startDate and range.endDate
      query = {
        addedDate: {
          $gte: new Date(range.startDate)
          $lte: new Date(range.endDate)
        }
      }

    PromedArticles.find(query, {
      sort: {addedDate: -1}
      limit: limit || 100
    })


Meteor.methods
  curatePromedArticle: (id, accepted) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      if accepted
        PromedArticles.update({_id: id}, {$set: {reviewed: true}})
