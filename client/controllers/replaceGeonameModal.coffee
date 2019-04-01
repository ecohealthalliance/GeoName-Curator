import Incidents from '/imports/collections/incidentReports'
import formatLocation from '/imports/formatLocation'

Template.replaceGeonameModal.helpers
  original: -> formatLocation(Template.instance().data.original)
  updated: -> formatLocation(Template.instance().data.updated)

Template.replaceGeonameModal.events
  'click .update-all': (event, instance) ->
    originalGeonameId = instance.data.original.id
    Incidents.find().map (incident)->
      if incident.locations.some((location) -> location.id == originalGeonameId)
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
