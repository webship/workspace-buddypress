@friends
Feature: Friends and their requests
  As a member of the community
  I want to ask other members to be friends and answer their requests
  So that I follow the people I care about

  Scenario: A request is sent, seen, mailed and rejected
    Given "newcomer" and "member" are not friends
    And I am a logged in user with the "newcomer" user
    When I go to the profile of "member"
    Then the profile's friendship button should read "Add Friend"
    When I press "Add Friend" on the profile
    Then the profile's friendship button should read "Cancel Friendship Request"
    And a community mail "New friendship request from Newcomer Test" should be sent to "member"
    And the community mail "New friendship request from Newcomer Test" to "member" should contain "Newcomer Test"
    Given I am a logged in user with the "member" user
    When I go to my friendship requests
    Then my friendship requests should list "newcomer"
    And my notifications should list "You have a friendship request from Newcomer Test"
    When I go to my friendship requests
    And I reject the friendship request of "newcomer"
    And I go to my friendship requests
    Then my friendship requests should not list "newcomer"
    And the friends of "member" should not list "newcomer"

  Scenario: A request is accepted, then the friendship is cancelled
    Given "newcomer" and "member" are not friends
    And I am a logged in user with the "newcomer" user
    When I go to the profile of "member"
    And I press "Add Friend" on the profile
    Given I am a logged in user with the "member" user
    When I go to my friendship requests
    And I accept the friendship request of "newcomer"
    Then the friends of "member" should list "newcomer"
    And the friends of "newcomer" should list "member"
    When I go to the profile of "newcomer"
    Then the profile's friendship button should read "Cancel Friendship"
    When I press "Cancel Friendship" on the profile
    Then the profile's friendship button should read "Add Friend"
    And the friends of "member" should not list "newcomer"

  Scenario: A request withdrawn by the one who sent it
    Given "newcomer" and "moderator" are not friends
    And I am a logged in user with the "newcomer" user
    When I go to the profile of "moderator"
    And I press "Add Friend" on the profile
    And I press "Cancel Friendship Request" on the profile
    Then the profile's friendship button should read "Add Friend"
    Given I am a logged in user with the "moderator" user
    When I go to my friendship requests
    Then my friendship requests should not list "newcomer"

  Scenario: Two accounts made friends for a scenario
    Given "newcomer" and "organizer" are friends
    And I am a logged in user with the "newcomer" user
    When I go to the members directory
    Then the row of "organizer" in the members directory should offer "Cancel Friendship"
