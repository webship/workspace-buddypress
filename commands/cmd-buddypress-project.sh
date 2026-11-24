#!/usr/bin/env bash

# workspace-name: BuddyPress (community on WordPress)

# Installed by the BuddyPress plugin (plugins.sh --install buddypress); __WORKSPACE__ is the workspace it was installed into.
#
# Build a community in a container: the WordPress plugin's builder makes the site (the latest WordPress, or the one
# --wordpress-version names), then the free BuddyPress plugin is added from the plugin directory, on DDEV by default
# or on the runtime --runtime names. With --install the community is set up (pretty addresses, registration open, the
# components a community uses); with --add-users the default accounts, one per place in the community; with
# --sample-content the profiles, friendships, groups, updates and the message the step pack's features name. The
# community's own tool is cmd-tools-buddypress-community.sh; WP-CLI (and its `bp` commands) is the WordPress plugin's
# tool: bash cmd-tools-wordpress-cli.sh <name> --run "bp component list".

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Set the versions: of BuddyPress (--version) and of WordPress (--wordpress-version).
site_version="latest";
wordpress_version="latest";

# Distribution.
distribution_name="buddypress";
distribution_title="BuddyPress";
distribution_webroot="";

ARGPARSE_DESCRIPTION="Build a ${distribution_title} community in __WORKSPACE__"
# The args file comes with the plugin: core/scripts/plugins/buddypress/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/buddypress/args/arg-buddypress.sh || exit 1 ;

shift $#;

buddypress_build ;
