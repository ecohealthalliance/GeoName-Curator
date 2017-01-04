@feeds
Feature: Feeds

  Background:
    Given I am logged in as an admin
    And I select feeds from the settings dropdown

  Scenario: Submit a feed
    When I add the feed "http://www.testfeed.com"
    Then I should see a "success" toast
    And I should see content "http://www.testfeed.com"

  Scenario: Remove a feed
    When I add the feed "http://www.testfeed.com"
    Then I should see content "http://www.testfeed.com"
    And I dismiss the active toast
    Then I delete the feed
    And I "confirm" deletion
    Then I should not see content "http://www.testfeed.com"
