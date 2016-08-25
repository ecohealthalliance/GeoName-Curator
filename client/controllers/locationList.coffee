formatLocation = require '/imports/formatLocation.coffee'

Template.locationList.onCreated ->
  @locationView = new ReactiveVar(false)

Template.locationList.helpers
  incidentLocations: ->
    locations = {}
    counts = Template.instance().data.counts
    # Loop 1: Incident Reports ("counts")
    for count in counts
      if count?.locations
        # Loop 2: Locations within each "count" record
        for loc in count.locations
          if locations[loc.geonameId]  # Append the source, update the date
            mergedSources = _.union(loc.sources, count.url)
            currDate = new Date(locations[loc.geonameId].addedDate)
            newDate = new Date(Date.parse count.addedDate)
            if currDate < newDate
              locations[loc.geonameId].addedDate = newDate
            locations[loc.geonameId].sources = mergedSources
          else # Insert new item
            loc.sources = count.url
            loc.addedDate = count.addedDate
            locations[loc.geonameId] = loc
    # Return
    _.values(locations)

  getSettings: ->
    fields = [
      {
        key: "displayName"
        label: "Title"
        fn: (value, object, key) ->
          return formatLocation(
            name: object.displayName
            admin1Name: object.subdivision
            countryName: object.countryName
          )
      },
      {
        key: "addedDate"
        label: "Added"
        fn: (value, object, key) ->
          return moment(value).fromNow()
      },
      {
        key: "expand"
        label: ""
        cellClass: "open-row"
      }
    ]

    return {
      id: 'event-locations-table'
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showRowCount: false
      class: "table"
    }

Template.locationList.events
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    $parentRow = $target.closest("tr")
    if not $parentRow.hasClass("tr-details")
      currentLocationView = template.locationView.get()
      closeRow = $parentRow.hasClass("details-open")
      if currentLocationView
        template.$("tr").removeClass("details-open")
        template.$("tr.tr-details").remove()
        Blaze.remove(currentLocationView)
        template.locationView.set(false)
      if not closeRow
        $tr = $("<tr>").addClass("tr-details")
        $parentRow.addClass("details-open").after($tr)
        template.locationView.set(Blaze.renderWithData(Template.location, this, $tr[0]))
