do ->
  'use strict'

  module.exports = ->

    scrollWithinModal = (client, selector, element, padding) ->
      client.execute (selector, element, padding) ->
        offset = $(element).first().offset()
        if typeof offset == 'undefined'
          throw new Error 'Suggested incident report does not have any annotations.'
        $(selector).scrollTop(offset.top + padding)
      , selector, element, padding

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

    @When /^I add the first suggested event source$/, ->
      @client.clickWhenVisible('.open-source-form-in-details')
      @client.waitForVisible('#event-source')
      @client.clickWhenVisible('#suggested-articles li:first-child')
      @client.setValue('input[name="publishTime"]', '12:00 PM')
      @client.click('button.save-modal[type="button"]')

    @When /^I add the first suggested incident report$/, ->
      # SuggestedIncidentsModal
      @client.waitForVisible('#suggested-locations-form p.annotated-content')
      # make sure the element is within view (webdriver.io scroll doesn't work
      # inside eidr-connect modal)
      scrollWithinModal(@client,
          '#suggestedIncidentsModal div.suggested-incidents-wrapper',
          'span.annotation.annotation-text', -200)
      # we do not know if the suggestedIncidentsModal will have any annotations
      if @client.isVisible('span.annotation.annotation-text')
        @client.click('span.annotation.annotation-text')
        # SuggestedIncidentModal
        @client.waitForVisible('#suggestedIncidentModal div.modal-footer')
        scrollWithinModal(@client, '#suggestedIncidentModal',
            'button.save-modal[type="button"]', -200)
        @client.click('button.save-modal[type="button"]')
        @client.pause(2000)

    @When /^I can "([^"]*)" suggestions$/, (action) ->
      # store the number of incident reports / sources from the dom
      if action is 'cancel'
        @client.clickWhenVisible('button.confirm-close-modal[type="button"]')
        # confirm close modal
        @client.waitForVisible('#cancelConfirmationModal')
        @client.click('button.confirm[type="button"]')
      else
        @client.clickWhenVisible('#add-suggestions')
