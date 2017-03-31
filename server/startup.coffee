UserEvents = require '/imports/collections/userEvents.coffee'
incidentReportSchema = require '/imports/schemas/incidentReport.coffee'
Incidents = require '/imports/collections/incidentReports.coffee'
articleSchema = require '/imports/schemas/article.coffee'
Articles = require '/imports/collections/articles.coffee'
CuratorSources = require '/imports/collections/curatorSources'
Constants = require '/imports/constants.coffee'

fs = Npm.require('fs')
path = Npm.require('path')
FileHound = Npm.require('filehound')

Meteor.startup ->
  if CuratorSources.findOne(_source: "anc")
    return
  CuratorSources.remove(_source: "anc")
  files = FileHound.create()
    .paths(path.join(process.env.PWD, '.anc'))
    .ext('txt')
    .findSync()
  count = 0
  for file in files
    count += 1
    data = fs.readFileSync file, 'utf8'
    # remove leading white-spance
    textContent = data.replace(/^ +/mg, "")
    if textContent.length == 0
      console.log "No content:", file
      continue
    # Normalize post for display/subscription
    normalizedPost =
      _id: new Mongo.ObjectID()
      _source: "anc"
      _sourceId: file
      title: "[" + file.split('.anc/')[1] + "] " + textContent.slice(0, 60)
      addedDate: new Date()
      publishDate: if count < 100 then new Date("2017-3-28") else new Date("2017-3-1")
      content: textContent
      reviewed: false
      feedId: "anc"
      metadata:
        links: []
    #console.log file, textContent.slice(0, 110)
    CuratorSources.insert(normalizedPost)
  console.log count, "documents added"
