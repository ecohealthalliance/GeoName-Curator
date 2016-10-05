
@CuratorSources = new Meteor.Collection "curatorSources"

if Meteor.isServer
  ReactiveTable.publish "curatorSources", CuratorSources, {}

  Meteor.publish "curatorSources", (limit, range) ->
    query = {addedDate: {$exists: true}}

    if range and range.startDate and range.endDate
      query = {
        addedDate: {
          $gte: new Date(range.startDate)
          $lte: new Date(range.endDate)
        }
      }

    CuratorSources.find(query, {
      sort: {addedDate: -1}
      limit: limit || 100
    })


Meteor.methods
  curateSource: (id, accepted) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      if accepted
        CuratorSources.update({_id: id}, {$set: {reviewed: true}})