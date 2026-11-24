import test from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';

import { register, assistantContext, PLATFORM, BASE, COMMANDS, AGENTS } from '../src/index';

// Compiled, these tests run from dist/tests, so the package root is one folder further up.
const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const read = (f: string) => fs.readFileSync(path.join(PKG, f), 'utf8');
const manifest = JSON.parse(read('package.json')).workspacePlugin;

test('the manifest names the platform, and every file it names ships', () => {
  assert.strictEqual(manifest.name, PLATFORM);
  const named = [...manifest.commands.files, ...manifest.scripts.functions, ...manifest.scripts.args, ...manifest.scripts.machine,
    ...manifest.ai.agents, ...manifest.ai.skills, ...manifest.ai.commands, ...manifest.ai.prompts, ...manifest.features];
  for (const f of named) assert.ok(fs.existsSync(path.join(PKG, f)), `${f} is in the package`);
  assert.deepStrictEqual(manifest.commands.files.map((f: string) => path.basename(f)), COMMANDS);
  assert.deepStrictEqual(manifest.ai.agents.map((f: string) => path.basename(f, '.md')), AGENTS);
  assert.deepStrictEqual(manifest.commands.types, ['sites'], 'the commands go to sites folders only');
  assert.ok(manifest.needs.includes(BASE), `it needs the plugin it builds on, ${BASE}`);
  const files: string[] = JSON.parse(read('package.json')).files;
  for (const f of named) assert.ok(files.includes(f.split('/')[0]), `${f} is published with the package`);
});

test('the machine files land beside the functions, under the names the functions read', () => {
  const functions = read('scripts/functions/fun-buddypress.sh');
  assert.deepStrictEqual(manifest.scripts.machine.map((f: string) => path.basename(f)).sort(), ['community-site.php', 'community.feature']);
  for (const f of manifest.scripts.machine) {
    assert.ok(functions.includes(`\${WORKSPACE_SCRIPTS}/plugins/buddypress/${path.basename(f)}`), `the functions read ${path.basename(f)} where the installer puts it`);
  }
});

test('every command finds the workspace by itself, names its folder, and sources its args from where the installer puts them', () => {
  for (const f of manifest.commands.files) {
    const src = read(f);
    assert.match(src, /^#!\/usr\/bin\/env bash/, `${f} is a bash script`);
    assert.match(src, /WORKSPACE_SCRIPTS="\$\{WORKSPACE_SCRIPTS:-\$\(cd "\$\(dirname "\$\{BASH_SOURCE\[0\]\}"\)\/\.\.\/core\/scripts" && pwd\)\}"/, `${f} locates the tooling from its own path`);
    assert.match(src, /workspace\.__WORKSPACE__\.settings\.yml/, `${f} loads the settings of the folder it is installed into`);
    assert.match(src, /source \$\{WORKSPACE_SCRIPTS\}\/plugins\/buddypress\/args\/arg-[a-z-]+\.sh \|\| exit 1 ;/, `${f} reads its arguments from the plugin's args`);
    const last = src.trim().split('\n').pop() as string;
    assert.match(read('scripts/functions/fun-buddypress.sh'), new RegExp(`^function ${last.replace(/ ;$/, '')}\\(\\)`, 'm'), `${f} ends by calling a function the plugin defines`);
  }
  assert.match(read('commands/cmd-buddypress-project.sh'), /^# workspace-name: BuddyPress/m, 'the builder carries the name the Build list shows');
  assert.doesNotMatch(read('commands/cmd-tools-buddypress-community.sh'), /^# workspace-name:/m, 'the tool is no builder: it is not in the Build list');
});

test('the help of the builder and of the tool asks for nothing and changes nothing', () => {
  // The args files are argparse input: every option has a help line, and the flags the brief names are there.
  const args = read('scripts/args/arg-buddypress.sh');
  for (const flag of ['--install', '--add-users', '--sample-content', '--version', '--wordpress-version', '--launch', '--php-version']) {
    assert.match(args, new RegExp(`'${flag}'`), `the builder has ${flag}`);
  }
  const tool = read('scripts/args/arg-buddypress-community.sh');
  for (const flag of ['--add-users', '--cancel-users', '--sample-content', '--tidy']) {
    assert.match(tool, new RegExp(`'${flag}'`), `the community's tool has ${flag}`);
  }
  for (const src of [args, tool]) {
    assert.strictEqual((src.match(/parser\.add_argument\(/g) || []).length, (src.match(/help=/g) || []).length, 'every option says what it does');
    // The dashboard's Build form reads a help in single quotes (core/workspace-app/builder-args.js): one in double
    // quotes is drawn without its text, and an apostrophe inside one ends it early.
    assert.doesNotMatch(src, /help="/, 'every help is in single quotes, as the Build form reads it');
    for (const m of src.matchAll(/help='([^\n]*)'\)$/gm)) assert.doesNotMatch(m[1], /'/, `no apostrophe inside a help: ${m[1]}`);
  }
});

test('every shell script parses', () => {
  for (const f of [...manifest.commands.files, ...manifest.scripts.functions, ...manifest.scripts.args]) {
    const r = spawnSync('bash', ['-n', path.join(PKG, f)], { encoding: 'utf8' });
    assert.strictEqual(r.status, 0, `${f}: ${r.stderr}`);
  }
});

test('the functions carry the names the core\'s tools look for, and never write database settings', () => {
  const src = read('scripts/functions/fun-buddypress.sh');
  for (const fn of ['set_buddypress_users', 'add_buddypress_users', 'cancel_buddypress_users', 'testing_configure_buddypress', 'buddypress_build', 'buddypress_is_project', 'buddypress_community_tool', 'buddypress_write_claim', 'buddypress_community_site']) {
    assert.match(src, new RegExp(`^function ${fn}\\(\\) \\{`, 'm'), `${fn} is defined`);
  }
  assert.doesNotMatch(src, /^function wordpress_[a-z_]+\(\)/m, 'the WordPress plugin\'s functions are used, not redefined');
  assert.doesNotMatch(src, /--dbname|--dbuser|--dbpass|DB_(HOST|NAME|USER|PASSWORD)=/, 'the container tool owns the database settings');
  assert.match(src, /wp plugin install buddypress/, 'the free plugin, from the plugin directory');
  assert.match(src, /wp rewrite structure '\/%postname%\/'/, 'pretty addresses, which the community needs');
  assert.match(src, /wp rewrite flush/, 'the rules written again: a plugin activated from the command line does not write them');
  assert.match(src, /bp_version_updater\(\);/, 'the plugin\'s own install, which a plugin activated from the command line leaves to the administration');
  assert.match(src, /wp bp component activate/, 'the components, with the plugin\'s own command');
  assert.match(src, /users_can_register 1/, 'registration open, so the registration page answers');
  assert.match(src, /buddypress_community_site content/, 'the sample content');
  assert.match(src, /buddypress_community_site names/, 'the names the community shows, with its own functions');
  assert.doesNotMatch(src, /ddev stop -y/, 'ddev stop takes no -y');
});

test('every container call is a plain verb of the container tool', () => {
  const src = read('scripts/functions/fun-buddypress.sh').replace(/^\s*#.*$/gm, '');
  assert.doesNotMatch(src, /docker (exec|compose|run)|ddev-[A-Za-z${}_-]*-web/, 'no container is reached by its name');
  assert.doesNotMatch(src, /\.ddev\/config\.yaml/, 'the project file of the container tool is not read: a verb of the tool answers instead');
  const verbs = new Set([...src.matchAll(/\bddev ([a-z-]+)/g)].map((m) => m[1]));
  assert.deepStrictEqual([...verbs].sort(), ['exec', 'launch', 'start', 'wp'], 'the verbs the plugin runs');
  // The one file of the tool the plugin writes is its claim, which the core asks for by that name.
  const files = new Set([...src.matchAll(/\.ddev\/([A-Za-z0-9._-]+)/g)].map((m) => m[1]));
  assert.deepStrictEqual([...files], ['config.buddypress.yaml']);
});

test('the claim file is the plugin\'s own name, and a real overlay of the container tool', () => {
  const src = read('scripts/functions/fun-buddypress.sh');
  assert.match(src, /\.ddev\/config\.buddypress\.yaml/, 'the file the core reads as the plugin\'s claim: config.<plugin>.yaml');
  assert.match(src, /^web_environment:\n  - WEBSHIP_WORKSPACE_PLATFORM=buddypress$/m, 'one key of the tool\'s own, which nothing of the site reads');
  assert.match(src, /^function set_buddypress_users\(\) \{/m, 'the claim names a plugin with a user list: set_<plugin>_users');
});

test('the script that writes the community uses the plugin\'s own functions, and creates no account', () => {
  const src = read('scripts/community-site.php');
  for (const fn of ['xprofile_insert_field', 'xprofile_set_field_data', 'friends_add_friend', 'groups_create_group', 'groups_join_group', 'bp_activity_post_update', 'bp_activity_new_comment', 'groups_post_update', 'messages_new_message']) {
    assert.ok(src.includes(`${fn}(`), `${fn} writes it`);
  }
  assert.doesNotMatch(src, /wp_insert_user|wp_create_user|wp_delete_user/, 'accounts are the builder\'s, never the script\'s');
  // The reset puts friendships and memberships back without a stream item, a notification or a mail.
  assert.match(src, /\$GLOBALS\['webship_quiet'\] = true;/);
  for (const mode of ['content', 'reset', 'names', 'status']) assert.ok(src.includes(`case '${mode}':`), `the mode ${mode}`);
  // What came after the build is a run's: the build marks its newest items.
  assert.match(src, /update_option\( 'webship_community_built', \$mark, false \);/);
  assert.doesNotMatch(read('README.md') + read('scripts/args/arg-buddypress-community.sh'), /for good/, 'cancelling says what it does');
});

test('each agent is a definition the AI Agents folder can list: named after its file, described, on the fable model', () => {
  for (const f of manifest.ai.agents) {
    const src = read(f);
    const head = src.split('\n---\n')[0];
    assert.match(head, /^---\n/, `${f} opens with frontmatter`);
    assert.match(head, new RegExp(`^name: ${path.basename(f, '.md')}$`, 'm'));
    assert.match(head, /^description: .{80,}$/m, `${f} says when to use it`);
    assert.match(head, /^model: fable$/m);
    assert.match(head, /^tools:\n(  - \S+\n?)+/m);
    assert.match(src, /cmd-tools-testing\.sh|cmd-buddypress-project\.sh/, `${f} names the plugin's commands`);
  }
  const tester = read('ai/agents/buddypress-tester.md');
  assert.match(tester, /Never create an account in a suite/);
  assert.match(tester, /No platform name in a step phrase/);
  assert.match(tester, /Playwright MCP browser first/);
});

test('register() adds the assistant context and nothing else', () => {
  const calls: string[] = [];
  const api: any = { name: 'buddypress', addAssistantContext: (fn: () => string) => calls.push(fn()) };
  register(api);
  assert.strictEqual(calls.length, 1);
  assert.strictEqual(calls[0], assistantContext());
  for (const c of COMMANDS) assert.ok(calls[0].includes(c), `the assistant is told about ${c}`);
  for (const a of AGENTS) assert.ok(calls[0].includes(a), `the assistant is told about ${a}`);
  assert.ok(calls[0].includes('cmd-tools-wordpress-cli.sh'), 'and about the WP-CLI tool the site is run with');
});

test('the docs say container-based, name only what ships, and carry no personal value', () => {
  const docs = ['README.md', ...manifest.ai.agents, 'scripts/functions/fun-buddypress.sh'];
  for (const f of docs) {
    const src = read(f);
    assert.doesNotMatch(src, /DDEV-only/i, `${f}: the workspace is container-based, DDEV by default`);
    assert.doesNotMatch(src, /\/home\/(?!YOUR_USER)[a-z]/, `${f} carries no personal path`);
    const mails = src.match(/[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[a-z]{2,}/g) || [];
    for (const m of mails) assert.match(m, /@example\.(com|org)$/, `${f}: ${m} is not an example address`);
  }
  for (const c of COMMANDS) assert.ok(read('README.md').includes(c), `the README lists ${c}`);
});
