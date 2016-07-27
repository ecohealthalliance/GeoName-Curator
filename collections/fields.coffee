Fields = new Meteor.Collection "fields"

@grid ?= {}
@grid.Fields = Fields

if Meteor.isServer
  Meteor.publish "fields", ->
    Fields.find()
