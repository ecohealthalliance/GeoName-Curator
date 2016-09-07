inlineDateRangePicker = require '/ui/inlineDateRangePicker.coffee'

module.exports.incidentReportFormToIncident = (form)->
  $form = $(form)
  $articleSelect = $(form.articleSource)
  if $form.find("#singleDate").hasClass("active")
    rangeType = "day"
    $pickerContainer = $form.find("#singleDatePicker")
  else if $form.find("#preciseRange").hasClass("active")
    rangeType = "precise"
    $pickerContainer = $form.find("#rangePicker")
  else
    rangeType = "unbounded"
    $pickerContainer = $form.find("#rangePointPicker")

  selectedDates = inlineDateRangePicker.getSelectedDates($pickerContainer)

  unless form.articleSource.checkValidity()
    toastr.error('Please select an article.')
    form.articleSource.focus()
    return
  if form.hourPrecision.checked
    if not selectedDates
      toastr.error('Please select a date or date range.')
      return
    if rangeType is "precise"
      if form.startHour.value.length is 0
        toastr.error('Please select a starting hour.')
        form.startHour.focus()
        return
      if form.endHour.value.length is 0
        toastr.error('Please select an ending hour.')
        form.endHour.focus()
        return
    else if form.hour.value.length is 0
      toastr.error('Please select a time.')
      form.hour.focus()
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
    date: moment(form.date.value, "M/D/YYYY").toDate()
    locations: []
    status: form.status.value
  }
  if form.incidentType.value == "cases"
    incident.cases = parseInt(form.count.value, 10)
  else if form.incidentType.value == "deaths"
    incident.deaths = parseInt(form.count.value, 10)
  else if form.incidentType.value == "other"
    incident.specify = form.other.value.trim()
  else
    throw new Meteor.Error("unknown-type")

  if selectedDates
    start = selectedDates.startDate
    end = selectedDates.endDate
    incident.dateRangeType = rangeType
    incident.hourPrecision = form.hourPrecision.checked
    if form.hourPrecision.checked and form.timezone.value.length
      incident.timezone = form.timezone.value
    else
      incident.unknownTimezone = true
      incident.timezone = "EGST"

    if rangeType is "day"
      if form.hourPrecision.checked
        hour = $(form.hour).data("DateTimePicker").date().get("hour")
        start.set("hour", hour)
        end.set("hour", hour)
        end.add(1, "hour")
      incident.startDate = start.toDate()
      incident.endDate = end.toDate()
    else if rangeType is "precise"
      if form.hourPrecision.checked
        start.set("hour", $(form.startHour).data("DateTimePicker").date().get("hour"))
        end.set({hour: $(form.endHour).data("DateTimePicker").date().get("hour"), minute: 0})
      incident.startDate = start.toDate()
      incident.endDate = end.toDate()
    else
      if form.hourPrecision.checked
        start.set("hour", $(form.hour).data("DateTimePicker").date().get("hour"))
      if form.unboundedRangeType.value is "after"
        incident.startDate = start.toDate()
      else
        incident.endDate = start.toDate()

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