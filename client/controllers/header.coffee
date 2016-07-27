Template.navLinks.events
  'click': (e) ->
    #check event.target's class to see if the click was meant to open/close a dropdown
    if not $(e.target).hasClass("dropdown-toggle-nav") and $('.navbar-toggle').is(':visible')
      $('.navbar-collapse').collapse('toggle')

Template.navLinks.helpers
  checkActive: (routeName) ->
    if routeName is Router.current().location.get().path.slice(1)
      'active'
