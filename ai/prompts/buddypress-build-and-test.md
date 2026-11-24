Build a site with BuddyPress in a sites folder and prove it with its first webship-js features.

The launch command below is for Claude Code, the default; the text between the triple quotes can be given to another AI CLI as it is.

```
claude --permission-mode bypassPermissions """
Build the community named <name> in this sites folder and test it with webship-js
# ~/workspace/<dev|test|sandboxes|demos> · https://<name>.ddev.site/members/ · container-based (DDEV by default)
# the builder deletes a project of the same name first: stop if <name> is a site somebody still needs
# nothing on the host: no php, wp or composer outside the site's container; nothing paid, no account anywhere
# a feature to write or a run to read: the book Automated Functional Testing Recipes first (its README.md, then the matching chapter), from .claude/automated-functional-testing-recipes/ in the project, ~/.claude/automated-functional-testing-recipes/ or https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes

1. bash cmd-buddypress-project.sh <name> --install --add-users --sample-content
2. bash cmd-tools-buddypress-community.sh <name>
   tell me the versions, the address, the community and the accounts with their places in the community
3. bash cmd-tools-testing.sh <name>
   webship-js, the community's step pack with the WordPress one, the users registry, tests/features/community.feature
4. bash cmd-tools-testing.sh <name> --dry-run --path tests/features/community.feature
5. bash cmd-tools-testing.sh <name> --run --path tests/features/community.feature

If a command fails, show the line that failed and stop. Do not retry with other flags.
When the feature is green: the address, the versions, how many scenarios and steps passed.
Then ask me whether to keep the site or remove it with: bash cmd-tools-remove.sh <name>
"""
```
