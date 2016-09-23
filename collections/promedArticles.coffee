
@PromedArticles = new Meteor.Collection "promed_articles"

if Meteor.isServer
  ReactiveTable.publish "promedArticles", PromedArticles, {}

  Meteor.publish "promedArticles", (limit, range) ->
    query = {addedDate: {$exists: true}}
    if range and range.startDate and range.endDate
      query = {
        addedDate: {
          $gte: new Date(range.startDate)
          $lte: new Date(range.endDate)
        }
      }

    PromedArticles.find(query, {
      sort: {addedDate: -1}
      limit: limit || 100
    })


Meteor.methods
  curatePromedArticle: (id, accepted) ->
    if Roles.userIsInRole(Meteor.userId(), ['curator', 'admin'])
      if accepted
        PromedArticles.update({_id: id}, {$set: {reviewed: true}})


# Temp dummy data:
createDummyArticles = () ->
  console.log 'Populating with test article...'
  article = {
    "addedDate": new Date(),
    "date": new Date(),
    "source": {
      "url": "http://www.reporteepidemiologico.com/wp-content/uploads/2015/06/REC-1605.pdf",
      "edits": "[in Spanish, transl., edited]",
      "name": "Reporte Epidemiologico de Cordoba",
      "resolved": {}
    },
    "content": "The text content of the article with the header/footer metadata removed.",
    "communicatedBy": "ProMED-mail from HealthMap Alerts\n<promed@promedmail.org>",
    "annotations": [
      {
        "type": "ORGANIZATION",
        "label": "CDC",
        "textOffsets": [[0, 3]],
        "resolved": {}
      }
    ]
  }
  PromedArticles.insert(article)


Meteor.startup ->
  # createDummyArticles()

