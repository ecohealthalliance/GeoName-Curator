Template.incidentReports.helpers
  getSettings: ->
    fields = [
      {
        key: "count"
        label: "Incident"
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
        key: "date"
        label: "Date"
        fn: (value, object, key) ->
          if object.date
            return moment(value).fromNow()
          return ""
      },
      {
        key: "travelRelated"
        label: "Travel Related"
        fn: (value, object, key) ->
          if value
            return "Yes"
          return ""
      },
      {
        key: "species"
        label: "Species"
      }
    ]

    if Meteor.user()
      fields.push({
        key: "delete"
        label: ""
        cellClass: "remove-row"
      })

    fields.push({
      key: "expand"
      label: ""
      cellClass: "open-row"
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
  "click #event-incidents-table th": (event, template) ->
    template.$("tr").removeClass("details-open")
    template.$("tr.tr-details").remove()
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    $parentRow = $target.closest("tr")
    currentOpen = template.$("tr.tr-details")
    if $target.closest(".remove-row").length
      if window.confirm("Are you sure you want to delete this incident report?")
        currentOpen.remove()
        Meteor.call("removeIncidentReport", @_id)
    else if not $parentRow.hasClass("tr-details")
      closeRow = $parentRow.hasClass("details-open")
      if currentOpen
        template.$("tr").removeClass("details-open")
        currentOpen.remove()
      if not closeRow
        $tr = $("<tr>").addClass("tr-details").html(Blaze.toHTMLWithData(Template.incidentReport, this))
        $parentRow.addClass("details-open").after($tr)

Template.incidentModal.onCreated ->
  @incidentType = new ReactiveVar("")

Template.incidentModal.onRendered ->
  $(document).ready =>
    @$(".datePicker").datetimepicker({
      format: "M/D/YYYY",
      useCurrent: false
    })

Template.incidentModal.helpers
  articles: ->
    return Template.instance().data.articles
  showCountForm: ->
    type = Template.instance().incidentType.get()
    return type is "cases" or type is "deaths"
  showOtherForm: ->
    return Template.instance().incidentType.get() is "other"

Template.incidentModal.events
  "change select[name='incidentType']": (e, template) ->
    template.incidentType.set($(e.target).val())
  "click .save-modal, click .save-modal-close": (e, templateInstance) ->
    closeModal = $(e.target).hasClass("save-modal-close")
    form = templateInstance.$("form")[0]
    $articleSelect = templateInstance.$(form.articleSource)
    validURL = form.articleSource.checkValidity()
    unless validURL
      toastr.error('Please select an article.')
      form.articleSource.focus()
      return
    unless form.date.checkValidity()
      toastr.error('Please provide a valid date.')
      form.publishDate.focus()
      return
    unless form.incidentType.checkValidity()
      toastr.error('Please select an incident type.')
      form.incidentType.focus()
      return
    if form.count and form.count.checkValidity() is false
      toastr.error('Please provide a valid count.')
      form.count.focus()
      return
    if form.other and form.other.value.trim().length is 0
      toastr.error('Please specify the incident type.')
      form.other.focus()
      return

    incident = {
      eventId: templateInstance.data.userEventId
      species: form.species.value
      travel: form.travelRelated.checked
      date: form.date.value
      locations: []
      type: form.incidentType.value
      value: if form.count then form.count.value.trim() else form.other.value.trim()
      status: form.status.value
    }

    for child in $articleSelect.select2("data")
      if child.selected
        incident.url = child.text.trim()

    $loc = templateInstance.$("#incident-location-select2")
    for option in $loc.select2("data")
      incident.locations.push(
        geonameId: option.item.id
        name: option.item.name
        displayName: option.item.name
        countryName: option.item.countryName
        subdivision: option.item.admin1Name
        latitude: option.item.latitude
        longitude: option.item.longitude
      )

    Meteor.call("addIncidentReport", incident, (error, result) ->
      if not error
        $(".reactive-table tr").removeClass("details-open")
        $(".reactive-table tr.tr-details").remove()
        if closeModal
          Modal.hide(templateInstance)
        toastr.success("Incident report added to event.")
      else
        toastr.error(error.reason)
    )
