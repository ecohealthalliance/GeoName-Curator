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
  "locations":
    type: [Object]
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
  "locations.$.featureClass":
    type: String
  "locations.$.featureCode":
    type: String
  "locations.$.id":
    type: String
  "locations.$.latitude":
    type: String
  "locations.$.longitude":
    type: String
  "locations.$.name":
    type: String
  "locations.$.population":
    type: Number
)
module.exports = IncidentReportSchema
