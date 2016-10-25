userEventSchema = new SimpleSchema(
  _id:
    type: String
    optional: true
  articleCount:
    type: Number
  createdByUserId:
    type: String
  createdByUserName:
    type: String
  creationDate:
    type: Date
  eventName:
    type: String
  lastIncidentDate:
    type: Date
  lastModifiedByUserId:
    type: String
  lastModifiedByUserName:
    type: String
  lastModifiedDate:
    type: Date
  summary:
    type: String
)
module.exports = userEventSchema
