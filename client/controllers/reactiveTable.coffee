Template.reactiveTable.onRendered ->
  if @data.settings.keyboardFocus
    attrs = tabindex: '0'
    @$('tbody > tr').attr(attrs)

Template.reactiveTable.events
  'click tbody > tr': (event, instance) ->
    instance.$(event.currentTarget).blur()
