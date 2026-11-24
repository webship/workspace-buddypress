@activity
Feature: The activity stream
  As a member of the community
  I want to post updates, comment on them and keep the ones I like
  So that the community knows what I do and I keep up with it

  Scenario: A visitor reads the stream
    Given I am not logged in
    When I go to the activity stream
    Then the activity stream should show "Welcome to the Webship Community!" by "Organizer Test posted an update"
    And the activity stream should show "Club meeting on Thursday" by "posted an update in the group Webship Club"
    And the update "Welcome to the Webship Community!" should show the comment "Hello everyone, glad to be here."
    And the update "Welcome to the Webship Community!" should not offer "Delete"

  Scenario: An update posted, commented on and deleted
    Given I am a logged in user with the "member" user
    When I go to the activity stream
    And I post the update "Webship test update one"
    Then the activity stream should show "Webship test update one" by "Member Test posted an update"
    And the update "Webship test update one" should offer "Delete"
    When I comment "Webship test comment on my update" on the update "Webship test update one"
    Then the update "Webship test update one" should show the comment "Webship test comment on my update"
    And the update "Webship test update one" should offer "Comment 1"
    When I press "Delete" on the update "Webship test update one"
    Then the activity stream should not show "Webship test update one"

  Scenario: An update in a group of mine
    Given I am a logged in user with the "member" user
    When I go to the activity stream
    And I post the update "Webship test update in the club" in the group "Webship Club"
    Then the activity stream should show "Webship test update in the club" by "posted an update in the group Webship Club"
    When I go to the group "Webship Club"
    Then the activity stream should show "Webship test update in the club"

  Scenario: A comment on another member's update, and a favorite
    Given I am a logged in user with the "newcomer" user
    When I go to the activity stream
    And I comment "Webship test: welcome, everyone" on the update "Welcome to the Webship Community!"
    Then the update "Welcome to the Webship Community!" should show the comment "Webship test: welcome, everyone"
    And a community mail "replied to one of your updates" should be sent to "organizer"
    When I press "Mark as Favorite" on the update "The new pattern library is out"
    Then the update "The new pattern library is out" should offer "Remove Favorite"
    When I open the "My Favorites" tab of the activity stream
    Then the activity stream should show "The new pattern library is out"
    And the activity stream should not show "Welcome to the Webship Community!"
    When I press "Remove Favorite" on the update "The new pattern library is out"
    Then the activity stream should not show "The new pattern library is out"
    When I open the "All Members" tab of the activity stream
    Then the update "The new pattern library is out" should offer "Mark as Favorite"

  Scenario: The kinds of items, and an empty update
    Given I am a logged in user with the "member" user
    When I go to the activity stream
    And I show only "Group Memberships" in the activity stream
    Then the activity stream should show "joined the group Webship Club"
    And the activity stream should not show "Welcome to the Webship Community!"
    When I show only "Updates" in the activity stream
    Then the activity stream should show "Welcome to the Webship Community!"
    When I show only "Everything" in the activity stream
    And I open the "My Groups" tab of the activity stream
    Then the activity stream should show "Club meeting on Thursday"
    When I open the "All Members" tab of the activity stream
    And I post an empty update
    Then the update form should say "Please enter some content to post."
