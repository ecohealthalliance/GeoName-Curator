do ->
  'use strict'

  module.exports = ->

    @When /^I click on the create new event button$/, ->
      @client.waitForVisible('.create-event')
      @client.click('.create-event')

    @When /^I create an event with name "([^']*)" and summary "([^']*)"$/, (name, summary) ->
      @client.waitForVisible('#create-event-modal')
      @client.setValue('#eventName', name)
      @client.setValue('#eventSummary', summary)
      @client.submitForm('#createEvent')
      @client.pause(100)

    @When /^I delete the first item in the event list$/, ->
      @client.waitForVisible('.reactive-table tbody tr:first-child')
      elements = @client.elements('.reactive-table tbody')
      if elements.value.length <= 0
        throw new Error('Tracked Events table is empty')
      @client.click('.reactive-table tbody tr:first-child')
      @client.pause(100)
      @client.click('i.edit-event-details')
      @client.pause(500)
      @client.click('.delete-event')
