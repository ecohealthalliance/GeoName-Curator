
@PromedArticles = new Meteor.Collection "promed_articles"

@grid ?= {}
@grid.PromedArticles = PromedArticles

getPromedArticles = (userEventId) ->
  PromedArticles.find({userEventId: userEventId})







# Temp dummy data:
createDummyArticles = () ->
  console.log 'Populating with test article...'
  article = {
    "date": new Date(),
    "dateAdded": new Date(),
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

