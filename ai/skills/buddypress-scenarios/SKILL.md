---
name: buddypress-scenarios
description: Write and run webship-js scenarios for a community on WordPress with BuddyPress of the Webship Workspace with the BuddyPress step pack (`@webship-js/buddypress-steps`, which brings the WordPress step pack along) — the phrases by area (members and profiles, friends, the activity stream, groups and their management, private messages and notifications, the registration form, the administration, the mail), the accounts by handle, the traps found on a real community, and three example features. Use when asked to "write a scenario for the community", "test the groups of <site>", or "which step checks a friendship request".
argument-hint: '<site> [what to cover]'
---

# buddypress-scenarios

Scenarios for a community on WordPress with BuddyPress of a Webship Workspace (`~/workspace`, container-based, DDEV by
default), written from the steps of [`@webship-js/buddypress-steps`](https://github.com/webship/buddypress-steps), of
the WordPress step pack it brings along and of [webship-js](https://github.com/webship/webship-js) itself, and run in
the site's container by the workspace's own command. It comes with the BuddyPress plugin
(`@webship.co/workspace-buddypress`), like the builder (`cmd-buddypress-project.sh`), the community's tool
(`cmd-tools-buddypress-community.sh`) and the agents `buddypress-site-builder` and `buddypress-tester`.

## Where everything is

| What | Where |
| --- | --- |
| The site | `~/workspace/<folder>/<site>`, its community at `https://<site>.ddev.site/members/` (`<folder>` is a sites folder: `dev`, `test`, `sandboxes`, `demos`) |
| Its mail | the mail catcher of the project, `https://<site>.ddev.site:8026` |
| The suite's configuration | `<site>/cucumber.js`: the step definitions it loads, the users registry (`worldParameters.users`, with each account's `name`), the mail catcher (`mailUrl`) |
| The features | `<site>/tests/features/*.feature` (`community.feature` and `site.feature` are the first ones the setup wrote) |
| The community's steps | `<site>/node_modules/@webship-js/buddypress-steps/tests/step-definitions/*.steps.js` |
| The site's steps (login, administration) | `<site>/node_modules/@webship-js/wordpress-steps/tests/step-definitions/*.steps.js` |
| webship-js's steps | `<site>/node_modules/webship-js/tests/step-definitions/*.js` |
| The reports | `<site>/tests/reports/` |

## The order of work

1. **Make sure the testing stack is there.** From the sites folder:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site>
   ```
   It adds webship-js, both step packs (in one profile: the community's pack extends the WordPress one), the users
   registry with the handles of the community's accounts, the mail catcher, `tests/features/site.feature` and
   `tests/features/community.feature`, and makes sure the default accounts are on the site. It is safe to run again: it
   adds what is missing and keeps what was changed.
2. **Read the installed steps before writing a phrase.** They are the source of truth: the packs move, and a phrase
   from memory is a guess.
   ```bash
   cd ~/workspace/<folder>/<site>
   grep -hE "^(Given|When|Then)\(" node_modules/@webship-js/buddypress-steps/tests/step-definitions/*.steps.js
   ```
   Every step carries a comment block with five examples above it; open the file when a phrase is not obvious.
3. **Look at the page first** (the Playwright MCP browser, a tab of your own) when the scenario is about a page you
   have not seen.
4. **Write the feature** in `<site>/tests/features/`, from phrases that exist (the lists below).
5. **Match every step without a browser**, then run the feature, then the suite:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site> --dry-run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --tags "@critical"
   bash cmd-tools-testing.sh <site> --run
   ```
   A dry run says `Undefined` for a phrase no definition matches: fix the phrase, do not write a step for it.

## Accounts: a handle, never a password

```gherkin
Feature: Accounts
  Scenario: The newcomer logs in and opens its profile
    Given I am a logged in user with the "newcomer" user
    When I go to my profile
    Then I should be on the profile of "newcomer"
```

The handles of the default accounts: `admin` (the site's `administrator`), `organizer`, `moderator`, `member` and
`newcomer`; each shows in the community as "<Login> Test". A visitor is `Given I am not logged in`. Never create an
account in a scenario, and never log in as the workspace account.

## The phrases, by area

Members and profiles:

```gherkin
Given I am on the members directory
Then the members directory should list "Organizer Test"
Then the members directory should say "Viewing 1 - 5 of 5 active members"
When I search the members for "Moderator"
When I order the members by "Alphabetical"
Then the members directory should list "admin", "member" and "newcomer" in this order
When I open the "My Friends" tab of the members directory
Then the row of "newcomer" in the members directory should offer "Add Friend"
When I go to the profile of "member"
Then I should be on the profile of "member"
When I open the "Profile" tab
When I open "Edit" in the tab's menu
Then the page should offer the "Friends" tab with 2
Then the page should offer the button "Private Message"
Then the profile should show "Location" as "Nairobi"
Then the profile should not show the field "Website"
When I set my profile field "Location" to "Nairobi, Kenya"
When I let "All Members" see my profile field "Location"
When I save my profile
Then my profile field "Location" should be seen by "All Members"
```

Friends:

```gherkin
Given "newcomer" and "member" are not friends
Given "newcomer" and "organizer" are friends
When I press "Add Friend" on the profile
Then the profile's friendship button should read "Cancel Friendship Request"
When I go to my friendship requests
Then my friendship requests should list "newcomer"
When I reject the friendship request of "newcomer"
Then the friends of "member" should list "organizer"
```

The activity stream:

```gherkin
Given I am on the activity stream
When I post the update "Webship test update one"
When I post the update "Webship test update in the club" in the group "Webship Club"
Then the activity stream should show "Webship test update one" by "Member Test posted an update"
When I comment "Webship test comment" on the update "Welcome to the Webship Community!"
Then the update "Welcome to the Webship Community!" should show the comment "Webship test comment"
When I press "Mark as Favorite" on the update "The new pattern library is out"
Then the update "The new pattern library is out" should offer "Remove Favorite"
When I show only "Updates" in the activity stream
When I open the "My Favorites" tab of the activity stream
When I post an empty update
Then the update form should say "Please enter some content to post."
```

Groups:

```gherkin
Given I am on the groups directory
Then the groups list should show "Design Circle" with "Private Group / 2 members"
Then the row of the group "Webship Club" should offer "Join Group"
When I search the groups for "Circle"
When I go to the group "Webship Club"
When I press "Join Group" on the group page
Then the group page should say "You successfully left the group."
Then the group "Core Team" should not be found
Given "newcomer" is not a member of the group "Design Circle"
Then the members of the group "Webship Club" should list "newcomer"
Then the membership requests of the group "Design Circle" should list "newcomer"
When I accept the membership request of "newcomer" to the group "Design Circle"
Then the role of "moderator" in the group "Webship Club" should be "Moderator"
When I change the role of "member" in the group "Webship Club" to "Moderator"
Given there is no group "Webship test circle"
When I create the private group "Webship test circle" described as "A private group of a test run."
When I delete the group "Webship test circle"
```

Messages and notifications:

```gherkin
Given there is no conversation "Webship test message"
When I send the message "Webship test message" to "member" saying "Hello from a test."
When I go to my inbox
Then the box should list the unread conversation "Welcome to the club" with "organizer"
When I open the conversation "Welcome to the club"
Then the conversation should show "Hi Member, welcome!" from "organizer"
When I reply "Webship test reply" to the conversation
When I delete the conversation
Then the messages page should say "Messages deleted"
When I go to my notifications
Then my notifications should list "Organizer Test sent you a new private message"
When I mark the notification "Organizer Test sent you a new private message" as read
When I turn off the email for "A member sends you a friendship request"
Then the email for "A member sends you a friendship request" should be off
```

The registration form, the mail and the administration:

```gherkin
Given I am on the registration page
Then the registration form should ask for "Name (required)"
When I try to register as "member" with the email "member@example.com" and the name "Webship test person"
Then the registration should be refused with "Sorry, that username already exists!"
Then a community mail "New friendship request from Newcomer Test" should be sent to "member"
Then the community mail "New message from Organizer Test" to "member" should contain "Hello from a test."
Then no community mail "New friendship request" should be sent to "member"
Then the community component "Friend Connections" should be active
Then the profile fields should list "Location" in "Base (Primary)"
Then the administration's groups should list "Core Team" with "Hidden"
Then the administration's activity should list "Welcome to the Webship Community!"
```

## Three example features

`examples/` beside this file holds three features that pass on a fresh site built with `--install --add-users
--sample-content`; copy one into `<site>/tests/features/` to start from it:

- `examples/friends-and-notifications.feature`: a request sent, mailed, seen and rejected; one accepted, then the
  friendship cancelled; a request withdrawn; two accounts made friends for a scenario.
- `examples/groups-and-requests.feature`: the groups directory for a visitor and a member, a public group joined and
  left, a private group's request rejected and accepted, a hidden group seen by its members only.
- `examples/the-activity-stream.feature`: the stream of a visitor, an update posted, commented on and deleted, an update
  in a group, a comment on another member's update and a favorite, the kinds of items, an empty update refused.

## Traps found on a real community

- **The lists fill after the page loaded.** The members and groups directories and the activity stream show "Loading
  the members of your community. Please wait." first; the steps wait for the list. A search, an order or a tab asks the
  site again: use the steps, which wait for that answer, not a click and a text check.
- **Many buttons answer without a new page.** "Add Friend", "Join Group", "Leave Group", "Mark as Favorite" change in
  place; a count in the same row (a group's "3 members") stays until a reload. The steps wait for the new state.
- **A delete asks "Are you sure?"** (an update, a comment, a notification); the steps answer yes. A conversation is
  deleted for the account that deletes it only.
- **A plugin activated from the command line leaves its install to the first page of the administration**, which then
  turns the components back to their defaults: the builder runs the plugin's install itself first.
- **A field's visibility** ("This field may be seen by: …") hides it from whoever may not see it: a visitor does not
  see a field "All Members" may see.
- **The search term stays** for the other tabs of a directory: after a search, "My Friends" lists only the friends that
  match it.
- **A hidden group answers "not found"** to whoever is not in it; a private one shows its name and "Request
  Membership".

## The book

For any automated functional testing in this work (a Gherkin feature, a step definition, choosing a
step, a test run and its failures), read the book *Automated Functional Testing Recipes* first.

- **Where.** Use the first that exists: `.claude/automated-functional-testing-recipes/` in the project,
  `~/.claude/automated-functional-testing-recipes/` (installed by webship/webship-js-ai-agent,
  webship/webship-js-skills or webship/ai-agents), or
  https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes
- **How.** Its `README.md` first, then the chapter that matches the task (one file per chapter,
  named by its subject), not the single complete file.
- **Which wins.** The installed webship-js package and the step pack are the source of truth for
  step phrasing. When they differ from the book, follow them and say so.
- **For BuddyPress.** Start with `ch06-form-testing-recipes.md` (the profile, update, message and group forms and
  their errors), `ch09-table-list-testing.md` (the directories, the stream and the lists of a group),
  `ch10-authentication-authorization.md` (who may see a field, a private and a hidden group) and
  `ch21-when-tests-go-bad.md` (flaky, brittle and slow scenarios).
