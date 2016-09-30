Template.adminUser.helpers
  isCurrentUser: ->
    this._id == Meteor.userId()

  isCurator: ->
    Roles.userIsInRole(this._id, ["curator"])

  isAdmin: ->
    Roles.userIsInRole(this._id, ["admin"])

  name: ->
    this.profile.name

  email: ->
    return this.emails?[0].address

Template.adminUser.events
  'click .make-curator': (event, template) ->
    Meteor.call('makeCurator', template.data._id)

  'click .remove-curator': (event, template) ->
    Meteor.call('removeCurator', template.data._id)

  'click .make-admin': (event, template) ->
    Meteor.call('makeAdmin', template.data._id)

  'click .remove-admin': (event, template) ->
    Meteor.call('removeAdmin', template.data._id)

Template.createAccount.events
  'submit #add-account': (event) ->
    event.preventDefault()

    name = event.target.name.value.trim()
    email = event.target.email.value.trim()
    makeAdmin = event.target.admin.checked

    if name.length and email.length
      Meteor.call('createAccount', email, name, makeAdmin, (error, result) ->
        if error
          if error.error is 'allUsers.createAccount.exists'
            toastr.error("The specified email address is already being used")
          else
            toastr.error(error.error)
         else
           Router.go('admins')
           toastr.success("Account created for " + email)
        )
     else
       toastr.error("Enter an email address and name")
