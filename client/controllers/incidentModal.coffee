Template.incidentModal.events
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
