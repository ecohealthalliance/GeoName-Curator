import CuratorSources from '/imports/collections/curatorSources'
import { forEachAsync } from '/imports/utils'

busyProcessing = false
module.exports = ->
  if busyProcessing
    return
  else
    busyProcessing = true
  count = 0
  batch = CuratorSources.find({
    $or: [
      enhancements: $exists: false
    ,
      'enhancements.diagnoserVersion': $lt: '0.4.2'
    ],
    reviewed: {$in: [null, false]},
    feedId: "pubmed_sample"
  }, {
    limit: 20
    sort:
      addedDate: -1
  }).fetch()
  forEachAsync(batch, (article, next, done) ->
    count++
    Meteor.call('getArticleEnhancementsAndUpdate', article._id, {}, (error, enhancements)->
      if error
        console.log article
        console.log error
        done()
      else
        next()
    )
  , ->
    console.log "processed #{count} articles"
    busyProcessing = false
  )
