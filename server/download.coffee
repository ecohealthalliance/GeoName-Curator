Events = ->
  @grid.Events

Fields = ->
  @grid.Fields

download = ->
  
  unless @userId
    throw new Meteor.Error(403, "Must be signed in to download data")

  fields = Fields().find().fetch()
  events = Events().find({eidVal: "1"}, {sort: {eidID: 1}}).fetch()

  # csv
  headerRow = (field.displayName for field in fields).join(",")
  
  csvRows = [headerRow]
  for event in events
    row = []
    for field in fields
      if field.arrayName
        array = event[field.arrayName] or []
        output = _.unique(element[field.spreadsheetName] for element in array).join(", ")
      else
        output = event[field.spreadsheetName] or ''
      output = output.replace(/\"/g, "\"\"")
      row.push "\"#{output}\""
    csvRows.push row.join(",")

  csvData = csvRows.join("\n")

  # json
  eventsOutput = []
  for event in events
    eventObject = {}
    for field in fields
      if field.arrayName
        array = event[field.arrayName] or []
        output = _.unique(element[field.spreadsheetName] for element in array).join(", ")
      else
        output = event[field.spreadsheetName]
      if output
        eventObject[field.displayName] = output
      
    eventsOutput.push eventObject

  jsonData = JSON.stringify(eventsOutput)
  
  csv: csvData
  json: jsonData
    
Meteor.methods
  download: download