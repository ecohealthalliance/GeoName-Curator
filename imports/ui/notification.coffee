module.exports =
  notify: (type, text, delayTime=2000) ->
    data =
      text: text
      type: type
      delayTime: delayTime
    Blaze.renderWithData Template.notification, data, $('body')[0]
