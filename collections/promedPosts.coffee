if Meteor.isServer

  @PromedPosts = null
  try
    spaDb = new MongoInternals.RemoteCollectionDriver(process.env.SPA_MONGO_URL)
    @PromedPosts = new Meteor.Collection("posts", { _driver: spaDb })
  catch e
    console.warn 'Unable to connect to remote SPA mongodb.'

  Meteor.methods
    fetchPromedPosts: (limit) ->
      @unblock
      if PromedPosts
        query = {curated: {$ne: true}, scrapeDate: {$exists: true}}

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

recordNewPosts = (posts) ->
  for post in posts
    try
      # Normalize post for display
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

      # Mark original post as curated
      PromedPosts.update({_id: post._id}, {$set: {curated: true}})
    catch e
      console.warn 'Unable to parse ProMED post with id ' + post._id + 'due to malformed data.'