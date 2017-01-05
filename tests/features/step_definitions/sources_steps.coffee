do ->
  'use strict'

  module.exports = ->

    getTime = (date) ->
      hour = date.getHours()
      minutes = date.getMinutes()
      _minutes = if minutes < 10 then "0#{minutes}" else minutes
      _hour = switch hour
        when 0 then 12
        when hour > 12 then hour - 12
        else hour
      time = "#{_hour}:#{_minutes}"

    formatDate = (date) ->
      dateString = "#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear()}"

    getSourcesFromTable = (browser) ->
      browser.elements('#event-sources-table tbody tr')

    @When /^I click on the add source button$/, ->
      @client.pause(1000)
      @client.clickWhenVisible('.open-source-form-in-details')

    @When /^I create a source with a title of "([^']*)", url of "([^']*)", and datetime of now$/, (title, url) ->
      date = new Date()
      @client.waitForVisible('#add-source')
      @client.setValue('#title', title)
      @client.setValue('#article', url)
      @client.setValue('input[name=daterangepicker_start]', formatDate(date))
      @client.setValue('#publishTime', getTime(date))
      @browser.scroll(0, 1000)
      @client.click('#event-source .save-modal')

    @When /^I select the existing source$/, ->
      @client.clickWhenVisible('#event-sources-table tbody tr:first-child')

    @When /^I delete the existing source$/, ->
      @client.clickWhenVisible('.delete-source')

    @When /^I edit the existing source$/, ->
      @client.clickWhenVisible('.edit-source')

    @When /^I change the source title to "([^']*)" and datetime to now$/, (title) ->
      date = new Date()
      @client.waitForVisible('#add-source')
      @client.setValue('#title', title)
      @client.setValue('input[name=daterangepicker_start]', formatDate(date))
      @client.setValue('#publishTime', getTime(date))
      @browser.scroll(0, 1000)
      @client.click('#event-source .save-edit-modal')

    @Then /^I see the new source in the source table$/, ->
      if getSourcesFromTable(@browser).value.length <= 1
        throw new Error('New source is not in the source table')

    @Then /^I should see an empty sources table$/, ->
      @browser.waitForVisible('#event-sources-table tbody tr', 10000, true)
