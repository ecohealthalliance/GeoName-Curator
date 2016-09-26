incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'

Meteor.startup ->
  incidents = Incidents.find().fetch()
  for incident in incidents
    try
      incidentReportSchema.validate(incident)
    catch error
      console.log error
      console.log JSON.stringify(incident, 0, 2)
