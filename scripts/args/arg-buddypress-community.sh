#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The name of the project: a site of this folder that has BuddyPress.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='Add the default accounts, one per place in the community: administrator, organizer, moderator, member and newcomer. An account that is there keeps its password and gets its role and its name back.')
parser.add_argument('-c', '--cancel-users',
                    action='store_true',
                    default=False,
                    help='Delete the default accounts. The community removes what was theirs; --add-users then --sample-content bring them and the sample content back.')
parser.add_argument('-s', '--sample-content',
                    action='store_true',
                    default=False,
                    help='Add the community the test scenarios name (what is there already is kept): profile fields, friendships, groups and their members, updates, a private message.')
parser.add_argument('-t', '--tidy',
                    action='store_true',
                    default=False,
                    help='Take away what a stopped test run left (every update, comment, notification and message after the sample content, the groups and conversations named "Webship test …"), and put the friendships, memberships, profile fields and favorites back.')
ARGEOF
