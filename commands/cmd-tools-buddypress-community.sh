#!/usr/bin/env bash

# Installed by the BuddyPress plugin (plugins.sh --install buddypress); __WORKSPACE__ is the workspace it was installed into.
#
# The community of one site of this workspace, in the project's web container: say what it holds (each account's
# friends and groups, the updates), add or cancel the default accounts, add the sample content, take away what a
# stopped test run left. Nothing here runs on the host.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Distribution.
distribution_name="buddypress";

ARGPARSE_DESCRIPTION="The community of a site of __WORKSPACE__: what it holds, the default accounts, the sample content, a tidy-up"
# The args file comes with the plugin: core/scripts/plugins/buddypress/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/buddypress/args/arg-buddypress-community.sh || exit 1 ;

shift $#;

buddypress_community_tool ;
