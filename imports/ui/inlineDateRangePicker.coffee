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
  template.$(".inlineRangePicker").off("click.daterangepicker")
  template.$(".daterangepicker").removeClass("opensright")
  picker.setStartDate("")
  picker.setEndDate("")
  picker.show()
  $(document).off("mousedown.daterangepicker touchend.daterangepicker click.daterangepicker focusin.daterangepicker")

module.exports = createInlineDateRangePicker
