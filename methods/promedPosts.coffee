if Meteor.isServer
  PromedPosts = require '/imports/collections/promedPosts.coffee'
  CuratorSources = require '/imports/collections/curatorSources.coffee'

  Meteor.methods
    fetchPromedPosts: (limit, range) ->
      @unblock
      if PromedPosts
        query = {scrapeDate: {$exists: true}}

        if range and range.startDate and range.endDate
          query.scrapeDate = {
            $exists: true
            $gte: new Date(range.startDate)
            $lte: new Date(range.endDate)
          }

        posts = PromedPosts.find(query, {
          sort: {scrapeDate: -1}
          limit: limit || 100
          fields: {
            promedId: 1
            subject: 1
            content: 1
            scrapeDate: 1
            promedDate: 1
            articles: 1
            links: 1
          }
        }).fetch()

        recordNewPosts(posts)

        return true

  recordNewPosts = (posts) ->
    for post in posts
      try
        # Normalize post for display/subscription
        normalizedPost = {
          _source: "promed-mail"
          _sourceId: post.promedId
          title: post.subject.description
          content: post.content
          addedDate: post.scrapeDate
          publishDate: post.promedDate
          metadata: {
            articles: post.articles
            links: post.links
          }
        }
        CuratorSources.upsert({_id: post._id}, {$set: normalizedPost})

      catch e
        console.warn 'Unable to parse ProMED post with id ' + post._id + ' due to malformed data.'
        console.log e
