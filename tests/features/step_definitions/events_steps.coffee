do ->
  'use strict'

  module.exports = ->

    # @Given /^There is a test event with the name of "([^"]*)"$/, (eventName) ->
    #   @server.call('createTestingEvent', 'fakeid', eventName, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', eventName)
    #
    # @Given /^The test event has a source$/, (eventName) ->
    #   @client.pause(3000)
    #   source =
    #     userEventId: 'fakeid'
    #     url: 'http://feed.test'
    #     publishDate: new Date()
    #     publishDateTZ: 'EST'
    #   @server.call('addEventSource', source)

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
