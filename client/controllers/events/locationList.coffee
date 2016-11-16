formatLocation = require '/imports/formatLocation.coffee'

Template.locationList.onRendered ->
  @$('#locationFilter input').attr 'placeholder', 'Search locations'

Template.locationList.helpers
  incidentLocations: ->
    locations = {}
    incidents = Template.instance().data.incidents
    # Loop 1: Incident Reports
    for incident in incidents
      if incident?.locations
        # Loop 2: Locations within each incident report record
        for loc in incident.locations
          if locations[loc.id]  # Append the source, update the date
            mergedSources = _.without(_.union(loc.sources, incident.url), undefined)
            currDate = new Date(locations[loc.id].addedDate)
            newDate = new Date(Date.parse incident.addedDate)
            if currDate < newDate
              locations[loc.id].addedDate = newDate
            locations[loc.id].sources = mergedSources
          else # Insert new item
            loc.sources = incident.url
            loc.addedDate = incident.addedDate
            locations[loc.id] = loc
    # Return
    _.values(locations)

  getSettings: ->
    fields = [
      {
        key: 'name'
        label: 'Name'
        fn: (value, object, key) ->
          return formatLocation(object)
      }
      {
        key: 'addedDate'
        label: 'Added'
        fn: (value, object, key) ->
          return moment(value).fromNow()
      }
      {
        key: 'expand'
        label: ''
        cellClass: 'action open-down'
      }
    ]

    id: 'event-locations-table'
    fields: fields
    showFilter: false
    showNavigationRowsPerPage: false
    showRowCount: false
    class: 'table'
    filters: ['locationFilter']


Template.locationList.events
  'keyup .reactive-table-input': (event, template) ->
    if event.target.value.length
      template.$('tr').removeClass('open')
      template.$('tr.details').remove()

  'click #event-locations-table th': (event, template) ->
    template.$('tr').removeClass('open')
    template.$('tr.details').remove()

  'click .reactive-table tbody tr': (event, template) ->
    $target = $(event.target)
    $parentRow = $target.closest('tr')
    if not $parentRow.hasClass('details')
      currentOpen = template.$('tr.details')
      closeRow = $parentRow.hasClass('open')
      if currentOpen
        template.$('tr').removeClass('open')
        currentOpen.remove()
      if not closeRow
        $parentRow.addClass('open').after $('<tr>').addClass('details')
        Blaze.renderWithData Template.location, @, $('tr.details')[0]
