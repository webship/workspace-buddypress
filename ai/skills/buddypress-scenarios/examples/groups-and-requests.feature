@groups
Feature: Groups: the directory, joining and leaving, a private group's request
  As a member of the community
  I want to find groups, join the open ones and ask to join the private ones
  So that I take part in what the community does together

  Scenario: The groups directory, for a visitor and for a member
    Given I am not logged in
    When I go to the groups directory
    Then the groups list should show "Webship Club" with "Public Group / 3 members"
    And the groups list should show "Design Circle" with "Private Group / 2 members"
    And the groups list should not show "Core Team"
    And the row of the group "Webship Club" should not offer "Join Group"
    And the group "Core Team" should not be found
    Given I am a logged in user with the "newcomer" user
    When I go to the groups directory
    Then the row of the group "Webship Club" should offer "Join Group"
    And the row of the group "Design Circle" should offer "Request Membership"
    When I search the groups for "Circle"
    Then the groups list should show "Design Circle"
    And the groups list should not show "Webship Club"

  Scenario: A member joins a public group and leaves it
    Given "newcomer" is not a member of the group "Webship Club"
    And I am a logged in user with the "newcomer" user
    When I go to the group "Webship Club"
    Then the group page should say "Public Group"
    And the page should offer the "Members" tab with 3
    When I press "Join Group" on the group page
    Then the page should offer the button "Leave Group"
    And the members of the group "Webship Club" should list "newcomer"
    When I go to the group "Webship Club"
    And I press "Leave Group" on the group page
    Then the group page should say "You successfully left the group."
    And the page should offer the button "Join Group"
    And the members of the group "Webship Club" should not list "newcomer"

  Scenario: A membership request to a private group, rejected by its organizer
    Given "newcomer" is not a member of the group "Design Circle"
    And I am a logged in user with the "newcomer" user
    When I go to the group "Design Circle"
    Then the group page should say "This is a private group and you must request group membership in order to join."
    When I press "Request Membership" on the group page
    Then the group page should say "Your membership request is awaiting approval from the group administrator."
    And the page should offer the button "Request Sent"
    And a community mail "Membership request for group: Design Circle" should be sent to "organizer"
    Given I am a logged in user with the "organizer" user
    Then my notifications should list "Newcomer Test requests group membership"
    And the membership requests of the group "Design Circle" should list "newcomer"
    When I reject the membership request of "newcomer" to the group "Design Circle"
    Then the membership requests of the group "Design Circle" should not list "newcomer"
    And a community mail "rejected" should be sent to "newcomer"

  Scenario: A membership request accepted: the newcomer is in the circle
    Given "newcomer" is not a member of the group "Design Circle"
    And I am a logged in user with the "newcomer" user
    When I go to the group "Design Circle"
    And I press "Request Membership" on the group page
    Given I am a logged in user with the "organizer" user
    When I accept the membership request of "newcomer" to the group "Design Circle"
    Then the members of the group "Design Circle" should list "newcomer"
    Given I am a logged in user with the "newcomer" user
    When I go to the group "Design Circle"
    Then the page should offer the button "Leave Group"

  Scenario: A hidden group, seen by its members only
    Given I am a logged in user with the "admin" user
    When I go to the group "Core Team"
    Then the group page should say "Hidden Group"
    Given I am a logged in user with the "newcomer" user
    Then the group "Core Team" should not be found
