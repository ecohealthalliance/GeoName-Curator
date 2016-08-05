Feature: Admins menu

  As a user with an admin account,
  so that I can perform administrative duties,
  I want to see the admins menu


  Scenario: Access user form
    Given I am logged in as an admin
    Then I can go to the account form

  @watch
  Scenario: Attempt to submit blank user form
    Given I am logged in as an admin
    And I can go to the account form
    Then I cannot submit a blank account form

  Scenario: Submit a valid form
    Given I am logged in as an admin
    And I can go to the account form
    Then I can submit a form that has email "test@test.com" and name "The Test"
