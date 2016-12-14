postMessageHandler = (event)->
  if not event.origin.match(/^https:\/\/([\w\-]+\.)*bsvecosystem\.net/) then return
  try
    request = JSON.parse(event.data)
  catch
    # Some things besides the BSVE will trigger the message handler, so if the
    # message isn't JSON, it is ignored and the parsing exception is swallowed.
    return
  if request.type == "eha.dossierRequest"
    title = "EIDR-Connect"
    url = window.location.toString()
    console.log "screenCapture starting..."
    html2canvas(document.body).then (canvas)->
      #Crop to viewport
      tempCanvas = document.createElement("canvas")
      tempCanvas.height = window.innerHeight
      tempCanvas.width = window.innerWidth
      tempCanvas.getContext("2d").drawImage(
        canvas,
        0, 0, # The top of the canvas is already cropped to the scrollY position
        window.innerWidth, window.innerHeight
        0, 0,
        window.innerWidth, window.innerHeight
      )
      console.log "screenCapture done"
      window.parent.postMessage(JSON.stringify({
        type: "eha.dossierTag"
        screenCapture: tempCanvas.toDataURL()
        url: url
        title: title
      }), event.origin)
  else if request.type == "eha.authInfo"
    Meteor.call("SetBSVEAuthTicketPassword", request, (error) ->
      if error
        window.parent.postMessage(JSON.stringify({
          type: 'eha.alert',
          msg: 'Authentication failed: EIDR-Connect',
          dismissable: true,
          cb: null
        }), event.origin)
      else
        Meteor.loginWithPassword(username: "bsve-" + request.user, request.authTicket, (error)->
          if error
            console.log error
        )
    )
window.addEventListener("message", postMessageHandler, false)
# The timeout is used to wait for BSVE.init to be called in the parent frame.
window.setTimeout ->
  window.parent.postMessage(JSON.stringify(type: "eha.authRequest"), "*")
, 1000
