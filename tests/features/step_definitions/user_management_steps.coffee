do ->
  'use strict'

  module.exports = ->

    @When /^I go to the account form$/, ->
      if @client.isVisible('button.navbar-toggle')
        @client.click('button.navbar-toggle')
      @browser.waitForVisible('.dropdown', 1000)
      @client.moveToObject('.dropdown-toggle-nav')
      @client.waitForVisible('.dropdown-menu.nav-dd', 1000)
      @client.click('.dropdown-menu.nav-dd a.user-accounts')

    @When /^I submit a form that has email "([^']*)" and name "([^']*)"$/, (address, profileName) ->
      @client.setValue('input[name="email"]', address)
      @client.setValue('input[name="name"]', profileName)
      @browser.submitForm('#add-account')
