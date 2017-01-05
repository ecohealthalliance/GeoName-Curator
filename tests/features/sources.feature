@sources
Feature: Sources

  Background:
    Given I am logged in as an admin
    And I navigate to "/user-events"
    And I navigate to the first event

  Scenario: I add a custom source to an event without adding incidents
    When I click on the add source button
    Then I create a source with a title of "Test Source", url of "http://www.promedmail.org/post/2579682", and datetime of now
    Then I should see content "SUGGESTED INCIDENT REPORTS"
    Then I close the "#suggestedIncidentsModal" modal
    And I should see content "Test Source"

  Scenario: I edit an existing source
    When I select the existing source
    Then I should not see content "Updated Title"
    Then I edit the existing source
    And I change the source title to "Updated Title" and datetime to now
    Then I should see content "Updated Title"

  Scenario: I delete an existing source
    When I select the existing source
    Then I delete the existing source
    And I "confirm" deletion
    Then I should see an empty sources table
