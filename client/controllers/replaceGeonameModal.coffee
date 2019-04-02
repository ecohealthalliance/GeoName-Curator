import Incidents from '/imports/collections/incidentReports'
import formatLocation from '/imports/formatLocation'

Template.replaceGeonameModal.helpers
  original: -> formatLocation(Template.instance().data.original)
  updated: -> formatLocation(Template.instance().data.updated)
  numberToReplace: ->
    originalGeonameId = Template.instance().data.original.id
    Incidents.find({
      'locations.id': originalGeonameId
    }).count()

Template.replaceGeonameModal.events
  'click .update-all': (event, instance) ->
    originalGeonameId = instance.data.original.id
    Incidents.find({
      'locations.id': originalGeonameId
    }).map (incident)->
      Meteor.call 'updateIncidentReport', {
        _id: incident._id
        locations: incident.locations.map((location)->
          if location.id == originalGeonameId
            instance.data.updated
          else
            location
        )
      }, (error, result) ->
        if error
          notify('error', 'There was a problem updating your incident reports.')
          return
    Modal.hide(instance)
