###
# InvalidNodeError - error thrown when an object is not instanceof Node
#
# @param {string} [message], (optional) the message to the user
###
export class InvalidNodeError extends Error
  name: 'InvalidNodeError'
  constructor: (message) ->
    @message = message || 'Is not instanceof Node.'
    super()

###
# InvalidGroupError - error thrown when an object is not instanceof Group
#
# @param {string} [message], (optional) the message to the user
###
export class InvalidGroupError extends Error
  name: 'InvalidGroupError'
  constructor: (message) ->
    @message = message || 'Is not instanceof Group.'
    super()
