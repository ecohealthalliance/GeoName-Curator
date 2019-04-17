Accounts.emailTemplates.siteName = "Geoname Curator"
Accounts.emailTemplates.from = "Geoname Curator <no-reply@eha.io>"

Meteor.startup ->
  unless Meteor.users.find().count()
    userData = Meteor.settings.private?.initial_user
    if userData
      userData.profile = { name: 'Admin' }
      console.log "[ Creating initial user with email #{userData.email} ]"
      Accounts.createUser userData
      newUserRecord = Meteor.users.findOne('emails.address': userData.email)
      if newUserRecord
        Roles.addUsersToRoles(newUserRecord._id, ['admin'])
    else
      console.warn '[ Meteor.settings.private.initial_user object \
                          is required to create the initial user record ]'
