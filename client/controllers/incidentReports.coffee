Template.incidentReports.onCreated ->
  @incidentType = new ReactiveVar("")

Template.incidentReports.onRendered ->
  $(document).ready =>
    @$(".datePicker").datetimepicker({
      format: "M/D/YYYY",
      useCurrent: false
    })
    @$("#countArticles").select2({
      tags: true
    })

Template.incidentReports.helpers
  showCountForm: ->
    type = Template.instance().incidentType.get()
    return type is "cases" or type is "deaths"
  showOtherForm: ->
    return Template.instance().incidentType.get() is "other"
  getSettings: ->
    fields = [
      {
        key: "count"
        label: "Count"
        fn: (value, object, key) ->
          if object.cases
            return object.cases + " case" + (if object.cases isnt "1" then "s" else "")
          else if object.deaths
            return object.deaths + " death" + (if object.deaths isnt "1" then "s" else "")
          else
            return object.specify
      },
      {
        key: "locations"
        label: "Locations"
        fn: (value, object, key) ->
          if object.locations
            return $.map(object.locations, (element, index) ->
              return element.displayName
            ).toString()
          return ""
      },
      {
        key: "addedDate"
        label: "Reported"
        fn: (value, object, key) ->
          return moment(value).fromNow()
      }
    ]
    
    if Meteor.user()
      fields.push({
        key: "delete"
        label: ""
        cellClass: "remove-row"
      })

    return {
      id: 'event-incidents-table'
      fields: fields
      showFilter: false
      showNavigationRowsPerPage: false
      showRowCount: false
      class: "table"
    }

Template.incidentReports.events
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    if $target.closest(".remove-row").length
      if window.confirm("Are you sure you want to delete this incident report?")
        Meteor.call("removeEventCount", @_id)
  "change select[name='incidentType']": (e, template) ->
    template.incidentType.set($(e.target).val())
  "submit #add-count": (e, templateInstance) ->
    e.preventDefault()
    $articleSelect = templateInstance.$(e.target.countArticles)
    validURL = e.target.countArticles.checkValidity()
    unless validURL
      toastr.error('Please select an article.')
      e.target.countArticles.focus()
      return
    unless e.target.date.checkValidity()
      toastr.error('Please provide a valid date.')
      e.target.publishDate.focus()
      return
    unless e.target.incidentType.checkValidity()
      toastr.error('Please select an incident type.')
      e.target.incidentType.focus()
      return
    if e.target.count and e.target.count.checkValidity() is false
      toastr.error('Please provide a valid count.')
      e.target.count.focus()
      return
    if e.target.other and e.target.other.value.trim().length is 0
      toastr.error('Please specify the incident type.')
      e.target.other.focus()
      return

    article = ""
    for child in $articleSelect.select2("data")
      if child.selected
        article = child.text.trim()

    $loc = templateInstance.$("#count-location-select2")
    allLocations = []

    for option in $loc.select2("data")
      allLocations.push(
        geonameId: option.item.id
        name: option.item.name
        displayName: option.item.name
        countryName: option.item.countryName
        subdivision: option.item.admin1Name
        latitude: option.item.latitude
        longitude: option.item.longitude
      )

    incidentCount = if e.target.count then e.target.count.value.trim() else e.target.other.value.trim()

    Meteor.call("addIncidentReport", templateInstance.data.userEvent._id, article, allLocations, e.target.incidentType.value, incidentCount, e.target.date.value, (error, result) ->
      if not error
        countId = result
        # $articleSelect.select2('val', '')
        # e.target.date.value = ""
        # e.target.incidentType.value = ""
        # templateInstance.incidentType.set("")
        # templateInstance.$("#count-location-select2").select2('val', '')
        toastr.success("Incident report added to event.")
      else
        toastr.error(error.reason)
    )
