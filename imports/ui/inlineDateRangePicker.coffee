createInlineDateRangePicker = (template, parentSelector, singleDatePicker) ->
  options = {
    parentEl: parentSelector
    template: Blaze.toHTML(Template.inlineDateRangePicker)
    singleDatePicker: singleDatePicker
    autoUpdateInput: false
  }

  $rangeContainer = template.$(parentSelector + ".inlineRangePicker").daterangepicker(options)
  picker = $rangeContainer.data("daterangepicker")
  if options.singleDatePicker
    picker.clickApply = (e) ->
      this.element.trigger('apply.daterangepicker', this);

  proxiedUpdateElement = picker.updateElement
  picker.updateElement = ->
    proxiedUpdateElement.apply(this, arguments)
    if this.element.is("input") and this.element.val().trim() is "Invalid date"
      this.element.val("")
  
  proxiedUpdateForm = picker.updateFormInputs
  picker.updateFormInputs = ->
    proxiedUpdateForm.apply(this, arguments)
    $startInput = this.container.find("input[name=daterangepicker_start]")
    $endInput = this.container.find("input[name=daterangepicker_end]")
    if $startInput.val() is "Invalid date"
      $startInput.val("")
    if this.endDate and $endInput.val() is "Invalid date"
      $endInput.val("")
  
  template.$(".inlineRangePicker").off("click.daterangepicker")
  template.$(".daterangepicker").removeClass("opensright")

  picker.show()

  clearSelectedDates($rangeContainer)

  $(document).off("mousedown.daterangepicker touchend.daterangepicker click.daterangepicker focusin.daterangepicker")

getSelectedDates = ($container) ->
  if $container.find("td.active").length
    picker = $container.data("daterangepicker")
    return {startDate: picker.startDate, endDate: picker.endDate}
  return null

clearSelectedDates = ($container) ->
  # The library can't handle setting the start and end dates to null
  # for an initially empty selection, so remove the active classes
  # and clear out the input values.
  $container.find("td.active").removeClass("active")
  $container.find("td.in-range").removeClass("in-range")
  $startInput = $container.find("input[name='daterangepicker_start']")
  $endInput = $container.find("input[name='daterangepicker_end']")
  if $startInput.length
    $startInput.val("")
  if $endInput.length
    $endInput.val("")

module.exports = {
  createInlineDateRangePicker: createInlineDateRangePicker
  getSelectedDates: getSelectedDates
  clearSelectedDates: clearSelectedDates
}
