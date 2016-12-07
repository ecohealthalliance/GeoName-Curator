Feature: Incident

  Background:
    Given I am on the site
    And I am logged in as an admin

  Scenario: Add incident report
    Given I can go to the event list
    Then I can click the first item in the event list
    Then I can add an incident report with count "100000001"
    And I can verify scatter plot group with count "100000001"
