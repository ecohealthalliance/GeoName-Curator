
@PromedPosts = new Meteor.Collection "posts"

if Meteor.isServer
  ReactiveTable.publish "promedPosts", PromedPosts, {}

  Meteor.publish "promedPosts", (limit, range) ->
    query = {sourceDate: {$exists: true}}
    query = {sourceDate: {$exists: true}, articles: {$exists: true, $ne: []}}
    if range and range.startDate and range.endDate
      query = {
        sourceDate: {
          $gte: new Date(range.startDate)
          $lte: new Date(range.endDate)
        }
      }

    PromedPosts.find(query, {
      sort: {sourceDate: -1}
      limit: limit || 100
    })


Meteor.methods
  curatePromedPost: (id, accepted) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      if accepted
        PromedPosts.update({_id: id}, {$set: {reviewed: true}})