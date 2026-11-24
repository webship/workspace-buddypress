/**
 * BuddyPress for Webship Workspace: a platform plugin, on top of the WordPress plugin.
 *
 * What the package carries is placed by the installer from the manifest: the builder and the community's tool in the
 * sites folders, their functions and argparse under core/scripts/plugins/buddypress/, the community's first feature
 * and the script that writes the accounts' places and the sample content beside them, and its AI items (ai/ in this
 * package) in the folder of their kind: the agents in AI Agents, the skill in AI Skills, the command in AI Commands,
 * the prompts in AI Prompts. The plugin needs the WordPress plugin (the manifest's `needs`): its builder starts from
 * that plugin's, and the site's WP-CLI is that plugin's tool. The dashboard needs nothing drawn for it: the builder is
 * in the Build list because it is a cmd-*-project.sh, the row menus are the core's, the AI items are listed like any
 * other. What register() adds is what the assistant is told.
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from the dashboard's own
 * files, so it can be installed from npm and removed without a trace.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';

/**
 * The plugin's name: the folder of its scripts and the name its functions carry. A community is a WordPress project
 * of the container tool: the plugin claims it with .ddev/config.buddypress.yaml (or the x-webship block on another
 * runtime), and the core's tools call its functions under buddypress.
 */
export const PLATFORM = 'buddypress';

/** The plugin it builds on (a need of the manifest): its builder makes the site, its CLI tool runs WP-CLI. */
export const BASE = 'wordpress';

/** The commands the installer places in every sites folder. */
export const COMMANDS = ['cmd-buddypress-project.sh', 'cmd-tools-buddypress-community.sh'];

/** The agents the installer places in the AI Agents folder. */
export const AGENTS = ['buddypress-site-builder', 'buddypress-tester'];

/** The skill the installer places in the AI Skills folder (a folder each, with its SKILL.md). */
export const SKILLS = ['buddypress-scenarios'];

/** The slash command the installer places in the AI Commands folder. */
export const AI_COMMANDS = ['buddypress-test'];

/** The prompts the installer places in the AI Prompts folder: each a whole launch command for a new session. */
export const PROMPTS = ['buddypress-build-and-test', 'buddypress-groups-round'];

/** What the assistant is told about BuddyPress in this workspace. */
export function assistantContext(): string {
  return [
    'BuddyPress (a plugin, @webship.co/workspace-buddypress, on top of the WordPress plugin): a community is built with',
    '`bash cmd-buddypress-project.sh <name> --install --add-users --sample-content` from a sites folder (dev, test, sandboxes, demos):',
    'the WordPress plugin\'s builder makes the site, then the free BuddyPress plugin is added from the plugin directory with the components a community uses',
    '(profiles, account settings, activity, notifications, friends, groups, private messages) and registration open,',
    'in a container like every other project: on DDEV by default, at https://<name>.ddev.site/members/, or with `--runtime docker|podman|kubernetes|lando|docksal` on that runtime, at the address the build prints;',
    '`--sample-content` adds the profiles, friendships, groups (a public, a private and a hidden one), updates and the message the step pack\'s features name,',
    '`--add-users` the default accounts, one per place in the community (administrator, organizer, moderator, member, newcomer).',
    '`bash cmd-tools-buddypress-community.sh <name>` says what the community holds; with `--add-users`, `--cancel-users`, `--sample-content` or `--tidy` it changes it.',
    'WP-CLI (with the community\'s own `bp` commands) is the WordPress plugin\'s tool: `bash cmd-tools-wordpress-cli.sh <name> --run "bp component list"`.',
    '`bash cmd-tools-testing.sh <name>` sets up webship-js with the BuddyPress step pack and the WordPress pack it extends; `--run` runs the suite.',
    `For BuddyPress work, hand over to the agents ${AGENTS.map((a) => `\`${a}\``).join(' and ')}.`,
    `The plugin also places the skill ${SKILLS.map((a) => `\`${a}\``).join(', ')} (the step pack's phrases, by area) in ai-skills/,`,
    `the command ${AI_COMMANDS.map((a) => `\`/${a} <site>\``).join(', ')} in ai-commands/ and the prompts ${PROMPTS.map((a) => `\`${a}\``).join(' and ')} in ai-prompts/.`,
    'Never run php, wp or composer on the host for a project; never install a paid add-on or connect the site to an account anywhere.',
  ].join(' ');
}

export function register(api: PluginApi): void {
  api.addAssistantContext(assistantContext);
}
