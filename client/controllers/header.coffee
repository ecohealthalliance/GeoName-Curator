Template.navLinks.events
  'mouseover li.dropdown': (event) ->
    $(event.currentTarget).addClass('open')
  'mouseout li.dropdown': (event) ->
    $(event.currentTarget).removeClass('open')
  'click': (e) ->
    #check event.target's class to see if the click was meant to open/close a dropdown
    if not $(e.target).hasClass("dropdown-toggle-nav") and $('.navbar-toggle').is(':visible')
      $('.navbar-collapse').collapse('toggle')
  "click #logOut": ->
    Meteor.logout()

Template.navLinks.helpers
  isCurator: ->
    Roles.userIsInRole(Meteor.userId(), ["admin", "curator"])
  checkActive: (routeName) ->
    if routeName is Router.current().location.get().path.slice(1)
      'active'
