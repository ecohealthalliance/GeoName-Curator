Template.curatorSourceDetails.helpers
  post: ->
    return PromedPosts.findOne({_id: @_id})
  formattedScrapeDate: ->
    return moment(Template.instance().data.sourceDate).format('MMMM DD, YYYY')
  formattedPromedDate: ->
    return moment(Template.instance().data.promedDate).format('MMMM DD, YYYY')

Template.curatorSourceDetails.events
  "click #accept-article": (event, template) ->
    Meteor.call("curatePromedPost", template.data._id, true)
    template.data.reviewed = true

Template.curatorArticle.onCreated ->
    console.log @
    @isOpen = new ReactiveVar(false)

Template.curatorArticle.helpers
  title: ->
    title = lodash.truncate(Template.instance().data.article.content, {length: 60})
    return title
  isOpen: ->
    return Template.instance().isOpen.get()

Template.curatorArticle.events
  "click .curator-inbox-section-head": (event, template) ->
    template.isOpen.set(!template.isOpen.curValue)