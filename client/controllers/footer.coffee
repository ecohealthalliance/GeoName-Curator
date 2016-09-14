Template.footer.helpers
  hideFooter: ->
    Router.current().route.getName() is 'event-map'
