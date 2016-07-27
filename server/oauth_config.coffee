Meteor.startup ->
  if Meteor.settings.google_oauth_client_id
    ServiceConfiguration.configurations.update(
      { service: 'google' }
      { '$set': {
        clientId: Meteor.settings.google_oauth_client_id
        secret: Meteor.settings.google_oauth_client_secret
      }}
      { upsert: true }
    )
