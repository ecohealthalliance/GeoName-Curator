Template.reactiveTable.onCreated ->
  @data.settings.keyboardFocus ?= true

Template.reactiveTable.onRendered ->
  if @data.settings.keyboardFocus
    @autorun =>
      if @context.ready.get()
        Meteor.defer =>
          @$('tbody > tr').attr(tabindex: '0')

Template.reactiveTable.events
  'click tbody > tr': (event, instance) ->
    instance.$(event.currentTarget).blur()
