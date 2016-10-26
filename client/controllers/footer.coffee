Template.footer.helpers
  hideFooter: ->
    pagesWithoutFooter = [
      'event-map'
      'curator-inbox'
    ]
    Router.current().route.getName() in pagesWithoutFooter
