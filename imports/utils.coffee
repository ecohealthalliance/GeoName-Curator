module.exports.incidentReportFormToIncident = (form)->
  $form = $(form)
  $articleSelect = $(form.articleSource)
  if $form.find("#singleDate").hasClass("active")
    rangeType = "day"
    $pickerContainer = $form.find("#singleDatePicker")
  else
    rangeType = "precise"
    $pickerContainer = $form.find("#rangePicker")

  picker = $pickerContainer.data("daterangepicker")

  unless form.articleSource.checkValidity()
    toastr.error('Please select an article.')
    form.articleSource.focus()
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
    species: form.species.value
    travelRelated: form.travelRelated.checked
    locations: []
    status: form.status.value
    dateRange: {
      type: rangeType
      start: picker.startDate.toDate()
      end: picker.endDate.toDate()
      cumulative: form.cumulative.checked
    }
  }
  if form.incidentType.value == "cases"
    incident.cases = parseInt(form.count.value, 10)
  else if form.incidentType.value == "deaths"
    incident.deaths = parseInt(form.count.value, 10)
  else if form.incidentType.value == "other"
    incident.specify = form.other.value.trim()
  else
    throw new Meteor.Error("unknown-type")

  for child in $articleSelect.select2("data")
    if child.selected
      incident.url = [child.text.trim()]

  $loc = $(form).find("#incident-location-select2")
  for option in $loc.select2("data")
    incident.locations.push(
      geonameId: option.item.geonameId or option.item.id
      name: option.item.name
      displayName: option.item.displayName or option.item.name
      countryName: option.item.countryName
      subdivision: option.item.subdivision or option.item.admin1Name
      latitude: option.item.latitude
      longitude: option.item.longitude
    )
  return incident