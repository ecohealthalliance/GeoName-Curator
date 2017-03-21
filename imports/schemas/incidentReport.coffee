IncidentReportSchema = new SimpleSchema
  _id:
    type: String
    optional: true
  url:
    type: String
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
    optional: true
  userEventId:
    type: String
    optional: true
  dateRange:
    type: Object
  "dateRange.type":
    type: String
    allowedValues: ["day","precise"]
    optional: true
  "dateRange.start":
    type: Date
    optional: true
  "dateRange.end":
    type: Date
    optional: true
  "dateRange.cumulative":
    type: Boolean
    optional: true
  travelRelated:
    type: Boolean
    optional: true
  approximate:
    type: Boolean
    optional: true
  disease:
    type: String
    optional: true
  resolvedDisease:
    type: Object
    optional: true
  "resolvedDisease.id":
    type: String
    optional: true
  "resolvedDisease.text":
    type: String
    optional: true
  species:
    type: String
    optional: true
  status:
    type: String
    optional: true
  "locations.$.admin1Name":
    type: String
    optional: true
  "locations.$.admin2Name":
    type: String
    optional: true
  "locations.$.alternateNames":
    type: [String]
    optional: true
  "locations.$.countryName":
    type: String
    optional: true
  "locations.$.featureClass":
    type: String
    optional: true
  "locations.$.featureCode":
    type: String
    optional: true
  "locations.$.id":
    type: String
  "locations.$.latitude":
    type: Number
    decimal: true
  "locations.$.longitude":
    type: Number
    decimal: true
  "locations.$.name":
    type: String
  "locations.$.population":
    type: Number
    optional: true
  deleted:
    type: Boolean
    optional: true
  deletedDate:
    type: Date
    optional: true
  accepted:
    type: Boolean
    optional: true
  textOffsets:
    type: [Number]
    optional: true

module.exports = IncidentReportSchema
