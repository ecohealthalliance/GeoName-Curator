do ->
  'use strict'

  module.exports = ->

    screenshotPath = './screenshots/incident'
    scrollWithinModal = (client, selector, element, padding) ->
      client.execute (selector, element, padding) ->
        offset = $(element).first().offset()
        $(selector).scrollTop(offset.top + padding)
      , selector, element, padding
    # workaround for https://github.com/ariya/phantomjs/issues/13896
    setCalcHeight = (client, selector) ->
      client.execute (selector) ->
        height = $(window).height() - 236
        $(selector).css({height: "#{height}px"})
      , selector

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
      if @client.isVisible('div.warn')
        text = @client.getText('div.warn')
        assert.equal(text.trim(), 'No incident reports could be automatically extracted from the article.')
        @client.pause(2000)
        return true
      if @client.isVisible('span.annotation.annotation-text')
        scrollWithinModal(@client,
            '#suggestedIncidentsModal div.suggested-incidents-wrapper',
            'span.annotation.annotation-text', -200)
        @client.clickWhenVisible('span.annotation.annotation-text')
        # SuggestedIncidentModal
        @client.waitForVisible('#suggestedIncidentModal div.modal-footer')
        scrollWithinModal(@client, '#suggestedIncidentModal',
            'button.save-modal[type="button"]', -200)
        @client.clickWhenVisible('button.save-modal[type="button"]')
        @client.saveScreenshot "#{screenshotPath}/add-first-suggested-incident-report.png"
        @client.pause(2000)
        return true
      throw new Error 'There was a problem loading suggested incident reports.'

    @Then /^I can "([^"]*)" suggestions$/, (action) ->
      setCalcHeight(@client, '.suggested-incidents-wrapper')
      if action is 'abandon'
        @client.saveScreenshot "#{screenshotPath}/abandon-suggested-incidents.png"
        @client.clickWhenVisible('button.confirm-close-modal[type="button"]')
        # confirm close modal
        @client.waitForVisible('#cancelConfirmationModal')
        @client.click('button.confirm[type="button"]')
        return true
      # get the original number of incident reports before button has been clicked
      elements = @client.elements('div.count :first-child')
      try
        expectedNumber = parseInt(@client.elementIdText(elements.value[0].ELEMENT).value, 10) + 1
      catch
        throw new Error 'Cound not get actual number of incident reports.'
      @client.saveScreenshot "#{screenshotPath}/confirm-suggested-incidents.png"
      # click add-suggestions button
      @client.clickWhenVisible('#add-suggestions')
      @client.pause(2000)
      # get the actual number of incident reports after button has been clicked
      elements = @client.elements('div.count :first-child')
      try
        actualNumber = parseInt(@client.elementIdText(elements.value[0].ELEMENT).value, 10)
      catch
        throw new Error 'Cound not get actual number of incident reports.'
      assert.equal(expectedNumber, actualNumber)
