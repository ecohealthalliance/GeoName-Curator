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
  allOptions = _.extend({
    parentEl: "#" + parentId
    template: Blaze.toHTML(Template.inlineDateRangePicker)
    singleDatePicker: options.singleDatePicker
    autoUpdateInput: false
    maxDate: options.maxDate
    minDate: options.minDate
  }, _.omit(options, 'singleDatePicker'))

  if options.startDate and options.endDate
    allOptions.startDate = options.startDate
    allOptions.endDate = options.endDate

  if options.autoApply
    allOptions.autoApply = true

  $rangeContainer = $parentElement.daterangepicker(allOptions)
  picker = $rangeContainer.data("daterangepicker")
  if options.singleDatePicker
    $(".singleDatePickerInput").show()
    picker.clickApply = (e) ->
      this.setEndDate(this.startDate)
      this.updateView()
      this.element.trigger('apply.daterangepicker', this);

  # Prevent the calendar from hiding
  picker.hide = -> @

  $(".inlineRangePicker").off("click.daterangepicker")
  $(".inlineRangePicker .daterangepicker").removeClass("opensright")

  picker.show()

  $(document).off("mousedown.daterangepicker touchend.daterangepicker click.daterangepicker focusin.daterangepicker")

  picker

module.exports = createInlineDateRangePicker
