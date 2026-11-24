Feature: The community answers, and its accounts are in it
  As the owner of the site
  I want the directories, the profiles and each default account to work
  So that a build that came out broken is caught before anything else is tested

  # Placed by the workspace's testing setup as a starting point: it is yours to change.
  # The accounts are the default ones (cmd-tools-buddypress-community.sh --add-users); a scenario logs in by a handle of
  # the users registry in cucumber.js, so no password is written here. It passes on a site built with --install
  # --add-users, with or without --sample-content: it reads only what the accounts make.

  @critical
  Scenario: A visitor finds the members of the community
    Given I am not logged in
    When I go to the members directory
    Then the members directory should list "organizer"
    And the members directory should list "newcomer"

  Scenario Outline: The <account> account logs in and opens its profile
    Given I am a logged in user with the "<account>" user
    When I go to my profile
    Then I should be on the profile of "<account>"
    And the page should offer the "Settings" tab

    Examples:
      | account   |
      | organizer |
      | moderator |
      | member    |
      | newcomer  |

  Scenario: The activity stream takes updates, and refuses an empty one
    Given I am a logged in user with the "member" user
    When I go to the activity stream
    And I post an empty update
    Then the update form should say "Please enter some content to post."
