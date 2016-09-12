IncidentReportSchema = new SimpleSchema(
  _id:
    type: String
    optional: true
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
  dateRange:
    type: Object
  "dateRange.type":
    type: String
    allowedValues: ["day","precise"]
  "dateRange.start":
    type: Date
  "dateRange.end":
    type: Date
  "dateRange.cumulative":
    type: Boolean
    optional: true
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
