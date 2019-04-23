import incidentReportSchema from '/imports/schemas/incidentReport'
import Incidents from '/imports/collections/incidentReports'
import CuratorSources from '/imports/collections/curatorSources'
import Constants from '/imports/constants'
import autoprocess from '/server/autoprocess'

fs = Npm.require('fs')
path = Npm.require('path')
FileHound = Npm.require('filehound')

Meteor.startup ->
  Meteor.setInterval(autoprocess, 1000 * 60 * 25)
  Meteor.setTimeout(autoprocess, 0)
  # Check to only run when there is no data present.
  # If this is commented out and the script runs a second time prior data
  # will be removed.
  if CuratorSources.findOne(_source: "anc")
    return
  CuratorSources.remove(_source: "anc")
  files = FileHound.create()
    .paths(path.join(process.env.PWD, '.anc'))
    .ext('txt')
    .findSync()
  count = 0
  dirNames = _.uniq(files.map (file)-> path.dirname(file))
  startDate = moment("2017-03-01")
  for file in files
    data = fs.readFileSync file, 'utf8'
    # remove leading white-spance
    textContent = data.replace(/^ +/mg, "")
    if textContent.length == 0
      console.log "No content:", file
      continue
    # Normalize post for display/subscription
    relPath = file.split('.anc/')[1]
    title = textContent.split(/\s+/).slice(0, 10).join(" ")
    # Make it so files in the same directory are all given the same publish
    # date so they are grouped together in the inbox.
    publishDate = moment(startDate).add(
        dirNames.indexOf(path.dirname(file)), 'day').toDate()
    normalizedPost =
      _id: new Mongo.ObjectID()
      _source: "anc"
      _sourceId: relPath.replace("/", "_")
      title: "[#{relPath}] #{title}"
      addedDate: new Date()
      publishDate: publishDate
      content: textContent
      reviewed: false
      feedId: "anc"
      metadata:
        links: []
    CuratorSources.insert(normalizedPost)
    count += 1
  console.log count, "documents added"
