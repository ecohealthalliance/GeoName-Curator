do ->
  'use strict'

  module.exports = ->

    firstEvent = '.reactive-table tbody tr:first-child'

    @When /^I click the first item in the event list$/, ->
      @client.clickWhenVisible(firstEvent)
      @client.pause(1000)

    @When /^I add an incident report with count "([^']*)"$/, (count) ->
      if not @client.waitForVisible(firstEvent)
        throw new Error('Event Incidents table is empty')
      @client.click('button.open-incident-form')
      # article URL
      @client.clickWhenVisible('span[aria-labelledby="select2-articleSource-container"]')
      @client.clickWhenVisible('#select2-articleSource-results li:first-child')
      # Location
      @client.click('input[placeholder="Search for a location..."]')
      @client.clickWhenVisible('#select2-incident-location-select2-results li:first-child')
      # Status
      @client.click('label[for="suspected"]')
      # Type
      @client.click('label[for="cases"]')
      # Count
      @client.waitForVisible('input[name="count"]')
      @client.setValue('input[name="count"]', count)
      # Submit
      @client.click('button.save-modal[type="button"]')

    @When /^I should see a scatter plot group with count "([^']*)"$/, (count) ->
      @client.pause(2000)
      selector = "[id*=\":#{count}:false\"]"
      groups = @client.elements(selector)
      if groups.value.length != 1
        throw new Error('ScatterPlot Group is empty')
