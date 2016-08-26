Template.incidentReports.helpers
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
  "click .open-incident-form": (event, template) ->
    Modal.show("incidentModal", {articles: template.data.articles, userEventId: template.data.userEvent._id})
  "click .reactive-table tbody tr": (event, template) ->
    $target = $(event.target)
    if $target.closest(".remove-row").length
      if window.confirm("Are you sure you want to delete this incident report?")
        Meteor.call("removeEventCount", @_id)

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
    $articleSelect = templateInstance.$(form.countArticles)
    validURL = form.countArticles.checkValidity()
    unless validURL
      toastr.error('Please select an article.')
      form.countArticles.focus()
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

    incidentCount = if form.count then form.count.value.trim() else form.other.value.trim()

    Meteor.call("addIncidentReport", templateInstance.data.userEventId, article, allLocations, form.incidentType.value, incidentCount, form.date.value, (error, result) ->
      if not error
        if closeModal
          Modal.hide(templateInstance)
        toastr.success("Incident report added to event.")
      else
        toastr.error(error.reason)
    )
