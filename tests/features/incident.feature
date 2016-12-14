Feature: Incident

  Background:
    And I am logged in as an admin

  Scenario: Add incident report
    When I navigate to "/user-events"
    And I click the first item in the event list
    And I add an incident report with count "100000001"
    Then I should see a "success" toast
    And I should see a scatter plot group with count "100000001"
