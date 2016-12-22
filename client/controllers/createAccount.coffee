validator = require('bootstrap-validator')

Template.createAccount.onRendered ->
  $.fn.validator.Constructor.FOCUS_OFFSET = 50
  @$('#add-account').validator()

Template.createAccount.events
  'submit #add-account': (event) ->
    return if event.isDefaultPrevented() # Form is invalid
    form = event.target
    event.preventDefault()
    name = form.name.value.trim()
    email = form.email.value.trim()
    makeAdmin = form.admin.checked

    Meteor.call 'createAccount', email, name, makeAdmin, (error, result) ->
      if error
        if error.error is 'allUsers.createAccount.exists'
          toastr.error('The specified email address is already being used')
        else
          toastr.error(error.error)
       else
         form.reset()
         toastr.success("Account created for #{email}")
