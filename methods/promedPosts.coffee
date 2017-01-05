if Meteor.isServer
  PromedPosts = require '/imports/collections/promedPosts.coffee'
  CuratorSources = require '/imports/collections/curatorSources.coffee'

  Meteor.methods
    fetchPromedPosts: (limit, range) ->
      @unblock
      endDate = range?.endDate || new Date()
      startDate = moment(endDate).subtract(2, 'weeks').toDate()
      if range?.startDate
        startDate = range.startDate
      query =
        feedId:
          $eq: '1'
        promedDate:
          $gte: new Date(startDate)
          $lte: new Date(endDate)

      posts = PromedPosts.find(query, {
        fields:
          feedId: 1
          promedId: 1
          subject: 1
          content: 1
          promedDate: 1
          articles: 1
          links: 1
      }).fetch()
      recordNewPosts(posts)

  recordNewPosts = (posts) ->
    for post in posts
      # Normalize post for display/subscription
      normalizedPost =
        _source: "promed-mail"
        _sourceId: post.promedId
        title: post.subject.raw
        addedDate: new Date()
        publishDate: post.promedDate
        content: post.content
        reviewed: false
        feedId: post.feedId
        metadata:
          links: post.links
      CuratorSources.upsert({_id: post._id}, {$setOnInsert: normalizedPost})
