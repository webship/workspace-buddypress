# @webship.co/workspace-buddypress

BuddyPress for the [Webship Workspace](https://github.com/webship/workspace) dashboard, on top of its
WordPress plugin ([`@webship.co/workspace-wordpress`](https://github.com/webship/workspace-wordpress)):
a builder that makes a real community in a container — WordPress with the free BuddyPress plugin and the
components a community uses — the default accounts (one per place in the community), the sample profiles,
friendships, groups, updates and message, the community's own tool, the
[BuddyPress step pack](https://github.com/webship/buddypress-steps) wired into the workspace's testing setup
next to the WordPress one it extends, and its AI items — two agents, a skill, a command and two prompts — each
listed in the workspace folder of its kind.

The workspace is container-based (DDEV by default): a community is a WordPress project like any other, so the
row menus the core draws (start, stop, launch, backup, clone, remove, tests) work on it unchanged. The plugin
claims its sites with a file of its own (`.ddev/config.buddypress.yaml`), so the Tests menu of the row offers
the community's test users.

It is made from the reference platform plugin, `@webship.co/workspace-wordpress`, and builds on it: the site is
made by that plugin's builder, and WP-CLI (with the community's own `wp bp` commands) is that plugin's tool
(`cmd-tools-wordpress-cli.sh`).

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require @webship.co/workspace-buddypress --with-needs   # npm install into the dashboard, with the WordPress plugin
bash core/scripts/plugins.sh --activate buddypress --with-needs                         # plugins.buddypress in settings.yml, and what it needs
bash core/scripts/plugins.sh --install buddypress                                       # the builder, the tool, functions, args, AI items
bash core/scripts/plugins.sh --configure buddypress                                     # nothing to configure: it has no settings file
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page. `--install` is
idempotent. `--uninstall` removes what it placed; an AI item you edited stays. The WordPress plugin
cannot be deactivated or uninstalled while this one is in use: take this one off first.

Everything the plugin carries lands in the folder it belongs to, when that folder is an active
workspace folder:

| What | Lands in |
| --- | --- |
| `cmd-buddypress-project.sh`, `cmd-tools-buddypress-community.sh` | every active sites folder: `dev/`, `test/`, `sandboxes/`, `demos/` |
| The community's first feature, and the script that writes the sample content, the names and a tidy-up | `core/scripts/plugins/buddypress/`, beside its functions |
| The agents `buddypress-site-builder`, `buddypress-tester` | `ai-agents/` |
| The skill `buddypress-scenarios` | `ai-skills/` |
| The command `/buddypress-test` | `ai-commands/` |
| The prompts `buddypress-build-and-test`, `buddypress-groups-round` | `ai-prompts/` |

There they are listed like any other item of the folder, and installed into Claude Code from there.

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder, for the builder: `dev`, `test`, `sandboxes`, `demos` (`dev` is the one added when none is there). The folder also carries `cmd-tools-testing.sh` and the Users tools this plugin's hooks answer to.
- `wordpress`, the WordPress plugin: the site is made by its builder (`wordpress_build`), its testing hook runs first on a community (the WordPress step pack, its users registry), and WP-CLI goes through its tool. `--with-needs` requires it from npm (`@webship.co/workspace-wordpress`), or from the folder beside this package when it was required from a path.
- `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`: the AI folders its agents, its skill, its command and its prompts are placed in.

`--require` says so, `--activate` and `--install` stop until the workspace has them, and `--with-needs` adds what is missing first:

```bash
bash core/scripts/plugins.sh --activate buddypress --with-needs   # dev, wordpress and the four AI folders are required, activated and installed first
bash core/scripts/plugins.sh --install buddypress
```

Everything the builder runs for a site runs in the site's own container, through the container tool the workspace already needs: WP-CLI is in the web container. The plugin asks for no command of its own on the machine.

## What the package holds

| Path | What it is |
| --- | --- |
| `commands/cmd-buddypress-project.sh` | The builder, in the Build list as **BuddyPress (community on WordPress)**, installed into every sites folder |
| `commands/cmd-tools-buddypress-community.sh` | The community's tool: what the community holds, the default accounts, the sample content, a tidy-up |
| `scripts/functions/fun-buddypress.sh` | The bash functions behind them, sourced by bootstrap once installed; the names the core's tools look for (`set_buddypress_users`, `add_buddypress_users`, `cancel_buddypress_users`, `testing_configure_buddypress`) |
| `scripts/args/arg-buddypress.sh`, `arg-buddypress-community.sh` | Their argparse; the Build form draws the builder's flags from the first |
| `scripts/community-site.php` | The script the functions run in the site with WP-CLI: the sample content, the names the community shows, a tidy-up and a status, each through the plugin's own functions (the step pack's own script) |
| `testing/community.feature` | The first feature a community gets when testing is set up |
| `ai/agents/buddypress-site-builder.md` | The agent that builds and maintains communities with these commands |
| `ai/agents/buddypress-tester.md` | The agent that writes and runs scenarios with the community's step pack |
| `ai/skills/buddypress-scenarios/` | The skill: the step pack's phrases by area, the traps found on a real community, three example features |
| `ai/commands/buddypress-test.md` | The slash command `/buddypress-test <site>`: set up, match every step, run, report |
| `ai/prompts/buddypress-build-and-test.md`, `buddypress-groups-round.md` | Two prompts: whole launch commands for a new session |
| `src/index.ts` | `register(api)`: what the assistant is told about BuddyPress here |
| `features/buddypress.feature` | Scenarios for the dashboard's own browser suite |
| `features/buddypress-runtimes.feature` | The row, the test users and two pages of the community of a site built on Docker Compose and on Kubernetes |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.

## The builder

Run it from a sites folder. `--help` is safe.

```bash
cd ~/workspace/dev
bash cmd-buddypress-project.sh mycommunity --install --add-users --sample-content
```

| Flag | What it does |
| --- | --- |
| `--install` | Install WordPress with the workspace account as the administrator, then add BuddyPress from the plugin directory, run its own install (its tables, its default components, its mail templates), turn on the components a community uses (Extended Profiles, Account Settings, Activity Streams, Notifications, Friend Connections, User Groups, Private Messaging) with the plugin's own command (`wp bp component activate`), and open the registration. Without it, WordPress is downloaded and BuddyPress put in its plugins, to activate once the site is installed |
| `--add-users` | With `--install`: add the default accounts, one per place in the community, each with its role on the site and the name the community shows |
| `--sample-content` | With `--install`: the profile fields "Location", "About me" (Base) and "Skills", "Website" (Work) with the accounts' values, three friendships, a public ("Webship Club"), a private ("Design Circle") and a hidden ("Core Team") group with their organizer, moderator and members, three updates with a comment and a favorite, and the private message "Welcome to the club" |
| `--version <x>` | The BuddyPress release (`latest` by default) |
| `--wordpress-version <x>` | The WordPress release (`latest` by default) |
| `--locale <x>` | The language WordPress is downloaded in |
| `--php-version <x>` | The PHP of the project container |
| `--runtime <name>` | The container runtime to build on: `ddev` (the default), `docker`, `kubernetes`, `podman`, `lando` or `docksal`. See [Runtimes](#runtimes) |
| `--launch` | Open the members directory when it is ready |

On DDEV the community answers at `https://mycommunity.ddev.site/members/` (`/groups/`, `/activity/`, `/register/`),
the administration at `/wp-admin`, the mail catcher at `https://mycommunity.ddev.site:8026`. The WordPress plugin's
builder makes the project (of the type `wordpress`) and installs the site; the container tool writes the database
settings, the builder writes none. A project of the same name is deleted first.

A plugin activated from WP-CLI leaves its install to the first page of the administration, which would then turn the
components back to their defaults: the builder runs the plugin's install itself first (`bp_version_updater()`).

Nothing paid and no account anywhere: the free plugin from the plugin directory, the theme WordPress installs with,
and content written by the plugin's own functions.

### Runtimes

```bash
bash cmd-buddypress-project.sh mycommunity --install --add-users --sample-content                        # DDEV, the default
bash cmd-buddypress-project.sh mycommunity --install --add-users --sample-content --runtime docker       # Docker Compose
bash cmd-buddypress-project.sh mycommunity --install --add-users --sample-content --runtime kubernetes   # a Kubernetes cluster
bash cmd-buddypress-project.sh mycommunity --install --add-users --sample-content --runtime lando        # Lando
bash cmd-buddypress-project.sh mycommunity --install --add-users --sample-content --runtime docksal      # Docksal
```

Without `--runtime` a build takes `container.runtime` of the workspace's `settings.yml`, then DDEV.
It needs a Webship Workspace with the container runtimes
([webship/workspace#694](https://github.com/webship/workspace/issues/694)); on an older one the
builder refuses `--runtime` and builds on DDEV only. Lando and Docksal need a Workspace whose runtime
layer has them ([webship/workspace#729](https://github.com/webship/workspace/issues/729),
[#730](https://github.com/webship/workspace/issues/730)).

| | DDEV | Docker Compose | Kubernetes | Podman | Lando | Docksal |
| --- | --- | --- | --- | --- | --- | --- |
| Build with `--install --add-users --sample-content` | Yes | RT_DOCKER | RT_K8S | Not yet run | Not yet run | Not yet run |
| The community and the administration; a login as the workspace account and the default accounts | Yes | RT_DOCKER | RT_K8S | Not yet run | Not yet run | Not yet run |
| `cmd-tools-buddypress-community.sh` (what the community holds), and WP-CLI (`cmd-tools-wordpress-cli.sh`) | Yes | RT_DOCKER | RT_K8S | Not yet run | Not yet run | Not yet run |
| Test users, cancelled and added | Yes | RT_DOCKER | RT_K8S | Not yet run | Not yet run | Not yet run |
| Mail caught by Mailpit | Yes | RT_DOCKER | RT_K8S | Not yet run | Not yet run | Not yet run |
| The testing setup and the first features | Yes | RT_DOCKER | RT_K8S | Not yet run | Not yet run | Not yet run |
| The step pack's examples, with the sample content | Yes | RT_DOCKER | RT_K8S | Not yet run | Not yet run | Not yet run |

"Yes" means it was run on a real site of that runtime. A runtime "Not yet run" runs the same code (the WordPress
plugin's builder on that runtime, then the same WP-CLI calls) and was not run yet.

| Runtime | The site's address | What the project carries |
| --- | --- | --- |
| DDEV | `https://mycommunity.ddev.site` | `.ddev/config.yaml`, and the plugin's claim `.ddev/config.buddypress.yaml` |
| Docker Compose | `http://127.0.0.1:<port>`, printed by the build | `compose.yaml`, `.webship/runtime/Dockerfile` |
| Kubernetes | `http://<node address>:<port>`, printed by the build | The same, and `k8s/` (the namespace `ws-mycommunity`) |
| Lando | `http://127.0.0.1:<port>`, printed by the build | `.lando.yml` (Lando's proxy stays off) |
| Docksal | `http://mycommunity.docksal.site`, on Docksal's own proxy | `.docksal/docksal.env`, `.docksal/docksal.yml` |

What differs on Docker Compose, Kubernetes, Lando and Docksal:

- **The claim** is `platform: buddypress` in the `x-webship` block (the core's `rt_claim`): no `.ddev/` folder is written there, and the row's Tests menu offers the community's list by it.
- **The site** is the WordPress plugin's, built on the same runtime: its `wp-config.php` with the stack's database (`db`/`db`/`db` on the host `db`), the address it is asked on, and the `.htaccess` Apache needs.
- **Cancelling the test users** deletes them, as on DDEV (WordPress's user delete; the community removes what was theirs): `--add-users`, then `cmd-tools-buddypress-community.sh <site> --sample-content`, put them and the sample content back.
- **HTTPS and a host name** are DDEV's: a runtime's address is plain HTTP.

The same commands work on every runtime: `cmd-tools-buddypress-community.sh`, `cmd-tools-add-users.sh`,
`cmd-tools-testing.sh`. The pattern is the Workspace's
[`core/docs/plugins-on-runtimes.md`](https://github.com/webship/workspace/blob/1.0.x/core/docs/plugins-on-runtimes.md).

### The plugin's claim on the project

A community is a project of the type `wordpress`, which is the WordPress plugin's. On DDEV the builder leaves
`.ddev/config.buddypress.yaml` in the project: a config overlay of the container tool with one key
(`web_environment: WEBSHIP_WORKSPACE_PLATFORM=buddypress`, in the web container's environment from its next start;
nothing of the site reads it). The file's name is what the workspace reads: a project that carries
`config.<plugin>.yaml` takes the test users of that plugin, so the row's Tests menu offers the community's list
(`buddypress`) instead of the WordPress one. On another runtime the claim is `platform: buddypress` in the `x-webship`
block (see [Runtimes](#runtimes)). A WordPress project that got the community plugin another way (its folder in the
plugins) is a community for the tools too.

### The community's tool

The community has a command line of its own in WP-CLI (`wp bp …`: components, members, groups, activity, friends).
The tool runs the plugin's `community-site.php` with WP-CLI in the site's container for the sample content, the
names, the tidy-up and the status, which reads and writes with the plugin's own functions, so the counts and the
notifications are the ones the plugin keeps.

```bash
bash cmd-tools-buddypress-community.sh mycommunity                    # each account's friends and groups, the updates
bash cmd-tools-buddypress-community.sh mycommunity --add-users        # the default accounts, with their names
bash cmd-tools-buddypress-community.sh mycommunity --cancel-users     # delete them; the community removes what was theirs
bash cmd-tools-buddypress-community.sh mycommunity --sample-content   # the sample community; what is there is kept
bash cmd-tools-buddypress-community.sh mycommunity --tidy             # take away what a stopped test run left
```

The tidy-up takes away every update, comment, notification and message that came after the sample content (the
build marks its newest items), the groups and conversations named "Webship test …", and puts the friendships, the
memberships and their roles, the profile fields and who may see them, the favorites and the build's message back,
without a new stream item, notification or mail.

WP-CLI is the WordPress plugin's tool, the community's commands with it:

```bash
bash cmd-tools-wordpress-cli.sh mycommunity --run "bp component list"
bash cmd-tools-wordpress-cli.sh mycommunity --run "bp group list"
bash cmd-tools-wordpress-cli.sh mycommunity --run "plugin get buddypress --field=version"
```

### The default accounts

| Account | Address | Role on the site | Place in the community | Handle in the tests |
| --- | --- | --- | --- | --- |
| `administrator` | `administrator@example.com` | administrator | Every profile and group; a member of the hidden "Core Team" | `admin` |
| `organizer` | `organizer@example.com` | subscriber | The organizer of "Webship Club", "Design Circle" and "Core Team" | `organizer` |
| `moderator` | `moderator@example.com` | subscriber | A moderator of "Webship Club" | `moderator` |
| `member` | `member@example.com` | subscriber | Friends with the organizer and the moderator, in two groups, a message in its inbox | `member` |
| `newcomer` | `newcomer@example.com` | subscriber | No friend and no group yet | `newcomer` |

One account per place in the community, each named after it ("Member Test" in the community), with the password of
the workspace's other default lists. They are for local sites and for tests; a test suite logs in as them and never
creates or deletes one. An account of your own, and the workspace account, stay when the default accounts are added or
cancelled.

The row's Tests menu offers **Add the test users** and **Cancel the test users** for a site this plugin claims: they
run the same list as

```bash
bash cmd-tools-add-users.sh mycommunity buddypress       # the core's tool, with the plugin's list
bash cmd-tools-cancel-users.sh mycommunity buddypress
```

Adding them again gives each its role and its name back. Cancelling deletes the accounts, and the community removes
what was theirs; `--add-users` then `--sample-content` bring the accounts and the sample community back.

### Test a community

```bash
bash cmd-tools-testing.sh mycommunity                 # webship-js, both step packs, the users registry, the first features
bash cmd-tools-testing.sh mycommunity --run           # run the suite in the container
bash cmd-tools-testing.sh mycommunity --run --path tests/features/community.feature
bash cmd-tools-testing.sh mycommunity --list-steps    # the step packs the project has, in one profile
```

`cmd-tools-testing.sh` is the workspace's own. For a community, this plugin's hook first runs the WordPress plugin's
(its pack, its users registry, `tests/features/site.feature`), then adds `@webship-js/buddypress-steps` to
`package.json` and its step definitions to `cucumber.js` in the same profile (the community's pack is an extension of
the WordPress one and loads it itself), adds the tags that keep the pack's assertions that must fail out of a normal
run, the mail catcher of the project (`mailUrl`), the handles of the community's accounts (with the addresses the mail
steps read and the names the community shows; overridable with `WP_<HANDLE>_USER` and `WP_<HANDLE>_PASSWORD`) in the
users registry, and `tests/features/community.feature` (the directories, each account's profile, an empty update
refused); it makes sure the default accounts are on the site. It is idempotent: a second run adds what is missing and
keeps what was changed.

## The AI items

`ai/` in the package holds one folder per kind, the manifest's `ai` block names each item, and
`--install` places it in the workspace folder of that kind.

| Kind | Item | Use it to |
| --- | --- | --- |
| Agent | `buddypress-site-builder` | Build, update, maintain or remove a community with the builder, the community's tool and the WP-CLI tool, in containers only, with nothing paid and no account anywhere |
| Agent | `buddypress-tester` | Set the testing stack up, look at the community in the Playwright MCP browser first, write scenarios from the packs' steps and run them; it never creates an account in a suite and never writes a platform name into a step phrase |
| Skill | `buddypress-scenarios` | Write a scenario from phrases that exist: the packs' steps by area, the handles of the users registry, the traps found on a real community, and three features that pass on a fresh site with the sample content |
| Command | `/buddypress-test <site> [feature or @tag]` | Run the suite of a site from inside a session: set up when missing, match every step, run, report what failed and why |
| Prompt | `buddypress-build-and-test` | Start a session that builds a community, says what it holds, sets the testing stack up and runs the first feature |
| Prompt | `buddypress-groups-round` | Start a session that writes and runs the scenario of a round of a group's life: a request, its answer, a role |

After `--install` each is in its folder on the dashboard. **Install** there puts an agent, a skill
or a command into Claude Code (`~/.claude/agents`, `~/.claude/skills`, `~/.claude/commands`), or
from the command line:

```bash
cd ~/workspace/ai-agents   && bash cmd-tools-ai-items.sh buddypress-tester --install
cd ~/workspace/ai-skills   && bash cmd-tools-ai-items.sh buddypress-scenarios --install
cd ~/workspace/ai-commands && bash cmd-tools-ai-items.sh buddypress-test --install
```

A prompt is not installed: it is the whole `claude …` launch command of a new session, and the
dashboard's **New screen** form lists it as a template. By hand, fill the placeholders in and run
the command of the file from the folder it names.

The items are written for any AI CLI, with Claude Code as the default shape: the frontmatter and
the file layout are Claude Code's, the body of each item is plain Markdown that names no tool or
feature of one CLI, a command says in words what its arguments are, and the text between the
triple quotes of a prompt can be given to another AI CLI as it is.

Every step phrase the items show is checked against the definitions of the community's step pack, of the
WordPress pack it brings and of webship-js (`tests/fixtures/step-definitions.txt`), and every command
and flag against the plugin's own, the WordPress plugin's and the workspace's.

## What is tied to the container tool

The builder and the tools call the container tool with plain verbs only (`ddev wp …`, `ddev exec`,
`ddev start`, `ddev launch`): no container is reached by its name, and the tool's own project file is
not read. On DDEV two things are DDEV's by name: the claim file lives in the tool's folder
(`.ddev/config.buddypress.yaml`, the place the workspace looks for it), and the addresses the builder
prints (`https://<name>.ddev.site`, the mail catcher at port 8026) are the ones DDEV's router gives a
project. On another runtime the claim is in the `x-webship` block and the addresses are the runtime's
(`rt_url`, `rt_mail_url`).

## Develop it

```bash
npm install     # builds dist/ (TypeScript)
npm run lint
npm test        # the manifest, the builder, the AI items, the functions against a scaffolded project
```

CI runs the same on Node.js 24 and 26, parses every shell script, and runs the plugin's
`features/buddypress.feature` against a dashboard with this plugin (and the WordPress plugin it needs)
installed (`webship/workspace/.github/workflows/plugin-browser-suite.yml`).

When the step pack's release line changes, refresh the fixture from a project whose testing stack is
set up: `node <this plugin>/tests/fixtures/refresh-step-definitions.js > <this plugin>/tests/fixtures/step-definitions.txt`.
