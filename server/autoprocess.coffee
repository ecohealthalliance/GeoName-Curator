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
    limit: 15
  }).fetch()
  forEachAsync(batch, (article, next, done) ->
    count++
    console.log "Processing id: " + article._id
    if article.content.length > 100000
      console.log "Article too long."
      return next()
    Meteor.call('getArticleEnhancementsAndUpdate', article._id, {}, (error, enhancements)->
      if error
        console.log "Error:"
        console.log error
        done()
      else
        next()
    )
  , ->
    console.log "processed #{count} articles"
    busyProcessing = false
  )
