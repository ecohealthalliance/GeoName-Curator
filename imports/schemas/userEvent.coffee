userEventSchema = new SimpleSchema(
  _id:
    type: String
    optional: true
  articleCount:
    type: Number
    optional: true
  createdByUserId:
    type: String
    optional: true
  createdByUserName:
    type: String
    optional: true
  creationDate:
    type: Date
    optional: true
  disease:
    type: String
  eventName:
    type: String
  lastIncidentDate:
    type: Date
    optional: true
  lastModifiedByUserId:
    type: String
    optional: true
  lastModifiedByUserName:
    type: String
    optional: true
  lastModifiedDate:
    type: Date
    optional: true
  summary:
    type: String
)
module.exports = userEventSchema
