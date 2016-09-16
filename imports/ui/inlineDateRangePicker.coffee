createInlineDateRangePicker = ($parentElement, options) ->
  parentId = $parentElement.prop("id")
  if !parentId
    # If the parent element doesn't have an id, generate one
    parentId = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) ->
      r = Math.random()*16|0
      v = if c is 'x' then r else (r&0x3|0x8)
      return v.toString(16)
    )
    $parentElement.prop("id", parentId)

  if !options then options = {}
  allOptions = {
    parentEl: "#" + parentId
    template: Blaze.toHTML(Template.inlineDateRangePicker)
    singleDatePicker: options.singleDatePicker
    autoUpdateInput: false
  }

  if options.startDate and options.endDate
    allOptions.startDate = options.startDate
    allOptions.endDate = options.endDate

  $rangeContainer = $parentElement.daterangepicker(allOptions)
  picker = $rangeContainer.data("daterangepicker")
  if options.singleDatePicker
    $(".singleDatePickerInput").show()
    picker.clickApply = (e) ->
      this.setEndDate(this.startDate)
      this.updateView()
      this.element.trigger('apply.daterangepicker', this);

  $(".inlineRangePicker").off("click.daterangepicker")
  $(".inlineRangePicker .daterangepicker").removeClass("opensright")

  picker.show()

  $(document).off("mousedown.daterangepicker touchend.daterangepicker click.daterangepicker focusin.daterangepicker")

module.exports = createInlineDateRangePicker
