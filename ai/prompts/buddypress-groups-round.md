Write and run the webship-js scenario of a round of a group's life on a community with BuddyPress.

The launch command below is for Claude Code, the default; the text between the triple quotes can be given to another AI CLI as it is.

```
claude --permission-mode bypassPermissions """
Write the scenario of a round of a group's life on the community of this site, and run it
# ~/workspace/<folder>/<site> · https://<site>.ddev.site/groups/ · container-based (DDEV by default)
# the phrases are in the buddypress-scenarios skill; the buddypress-tester agent is the one to hand this work over to
# look at the community first: in the Playwright MCP browser, in a tab of your own, do the round by hand once before writing its scenario
# a feature to write or a run to read: the book Automated Functional Testing Recipes first (its README.md, then the matching chapter), from .claude/automated-functional-testing-recipes/ in the project, ~/.claude/automated-functional-testing-recipes/ or https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes

The round: the newcomer <joins Webship Club|asks to join Design Circle>, the organizer <accepts|rejects> the request or <changes a role>,
and the group shows it: its members, its requests, the mail the community sent.

Read the installed steps first:
grep -hE '^(Given|When|Then)\(' node_modules/@webship-js/buddypress-steps/tests/step-definitions/*.steps.js

Write one feature in tests/features/<name>.feature, from phrases that exist.
Log in by the handle of the users registry (admin, organizer, moderator, member, newcomer):
no password in the feature, no account created by a scenario, no platform name in a step phrase.
Start from a known state (Given "newcomer" is not a member of the group ...); the steps put back what they change when the scenario ends.

Then, from the sites folder (cd ..):
bash cmd-tools-testing.sh <site> --dry-run --path tests/features/<name>.feature
bash cmd-tools-testing.sh <site> --run --path tests/features/<name>.feature

A failing scenario is a result: tell me what the community did, do not loosen the scenario.
When you are done: the scenario, the result of the run, and any step you could not find in the packs
"""
```
