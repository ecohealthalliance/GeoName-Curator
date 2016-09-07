IncidentReportSchema = new SimpleSchema(
  url:
    type: [String]
    label: "Source the incident is based on"
  addedByUserName:
    type: String
    optional: true
  addedByUserId:
    type: String
    optional: true
  addedDate:
    type: Date
    optional: true
  cases:
    type: Number
    optional: true
  deaths:
    type: Number
    optional: true
  specify:
    type: String
    optional: true
  locations:
    type: [Object]
    minCount: 1
  "locations.$":
    type: Object
    blackbox: true
  userEventId:
    type: String
  date:
    type: Date
    label: "Date of the incident"
  travelRelated:
    type: Boolean
    optional: true
  species:
    type: String
    optional: true
  status:
    type: String
    optional: true
)
module.exports = IncidentReportSchema