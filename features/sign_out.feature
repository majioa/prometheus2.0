Feature: User sign out
  To protect my account from unauthorized access
  A signed in user
  Should be able to sign out

  Scenario: User sign out
    Given I am signed up and confirmed as "email@person.com/password"
    When I sign in as "email@person.com/password"
    Then I should see "Welcome, email@person.com!"
    And I sign out
    Then I should see "Signed out successfully."
