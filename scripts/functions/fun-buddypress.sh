#!/usr/bin/env bash

# BuddyPress for the Webship Workspace: build a community on WordPress, add its default accounts (one per place in
# the community), add the sample content, and wire its step pack into the testing setup, next to the WordPress step
# pack it extends.
#
# Placed by `plugins.sh --install buddypress` in core/scripts/plugins/buddypress/functions/, where bootstrap sources it
# with the core's own functions and the WordPress plugin's: this plugin needs @webship.co/workspace-wordpress, and its
# builder starts from that plugin's wordpress_build. Everything runs in the project's container (DDEV by default:
# `ddev wp …`), never on the host. The container tool writes the database settings, so nothing here writes any.
#
# The community has a command line of its own in WP-CLI (`wp bp …`: components, members, groups, activity, friends);
# its components are turned on with it. The accounts' places and the sample content are written with the plugin's own
# functions by community-site.php (beside these functions), run with WP-CLI in the container:
#   bash cmd-tools-wordpress-cli.sh <site> --run "bp component list"
#
# A community is a project of the type `wordpress`. The builder leaves the claim of this plugin on the project, by
# which the core's tools take the test users of the community for it instead of the WordPress list:
# .ddev/config.buddypress.yaml on DDEV, `platform: buddypress` in the x-webship block on another runtime.
#
# The runtimes: a site is built on DDEV, or with --runtime on Docker Compose, Podman, Kubernetes, Lando or Docksal. The
# WordPress plugin's builder makes the site on that runtime, and the commands here are the same on each: `ddev <verb>`
# is DDEV itself on a DDEV project, and on another runtime the core's layer (fun-runtime.sh) gives the verb its
# meaning. What differs is behind buddypress_runtime: the address (buddypress_url) and where the claim is.
#
# Four names are the ones the core's tools look for:
#   set_buddypress_users          the default accounts        (cmd-tools-add-users.sh <project> buddypress)
#   add_buddypress_users          create them with WP-CLI     (the same tool, and --add-users of the builder)
#   cancel_buddypress_users       delete them                 (cmd-tools-cancel-users.sh <project> buddypress)
#   testing_configure_buddypress  the step pack in the testing stack (cmd-tools-testing.sh <project>)

# The step pack a community is tested with, and the release line it is required at. It brings the WordPress step pack
# along; the WordPress plugin's hook adds that one too.
readonly BUDDYPRESS_STEPS_PACKAGE='@webship-js/buddypress-steps';
readonly BUDDYPRESS_STEPS_VERSION='^2.0.0';

# The components a community uses, beside the two the plugin always runs (core and members).
readonly BUDDYPRESS_COMPONENTS='xprofile settings activity notifications friends groups messages';

# The default accounts: one per place in the community, the ones a scenario logs in as. Accounts are configuration,
# created once on the site; a test suite never creates or deletes one.
#   administrator  an administrator of the site (a second one: the installer's is the workspace account)
#   organizer      the organizer (administrator) of the sample groups
#   moderator      a moderator of the public group
#   member         a member with friends, groups and a message
#   newcomer       a member with no friend and no group yet
# Each but the administrator is a subscriber of the site. The name the community shows is "<Login> Test".
function set_buddypress_users() {
  users=(administrator organizer moderator member newcomer);
  local user ;
  for user in "${users[@]}" ; do
    printf -v "user_${user}_name" '%s' "${user}" ;
    printf -v "user_${user}_mail" '%s' "${user}@example.com" ;
    printf -v "user_${user}_password" '%s' 'dD.123123ddd' ;
    printf -v "user_${user}_role" '%s' 'subscriber' ;
    printf -v "user_${user}_fullname" '%s' "${user^} Test" ;
  done
  user_administrator_role='administrator' ;
}

# The runtime of the project in this folder, or of a new build (--runtime, else the workspace's setting, else DDEV). A
# core without the runtime layer has DDEV only.
function buddypress_runtime() {
  if declare -f runtime_of > /dev/null ; then runtime_of ; else echo 'ddev' ; fi
}

# The address of the site in this folder: https://<name>.ddev.site on DDEV, http://127.0.0.1:<port> on Docker Compose,
# Podman and Lando, the node's address and a port on Kubernetes, http://<name>.docksal.site on Docksal. Asked once the
# project is configured.
function buddypress_url() {
  if declare -f rt_url > /dev/null ; then rt_url ; else echo "https://${PROJECT_NAME}.ddev.site" ; fi
}

# Is this folder a community? The builder leaves its claim in it (the file on DDEV, the x-webship block on another
# runtime: the core's rt_is_platform reads both); a WordPress project that got the plugin another way has the plugin's
# folder, at its root or in its docroot.
function buddypress_is_project() {
  local project_path="$1" ;
  [ -f "${project_path}/.ddev/config.buddypress.yaml" ] && return 0 ;
  if declare -f rt_is_platform > /dev/null ; then
    rt_is_platform "${project_path}" buddypress && return 0 ;
  fi
  [ -f "${project_path}/wp-content/plugins/buddypress/bp-loader.php" ] && return 0 ;
  compgen -G "${project_path}/*/wp-content/plugins/buddypress/bp-loader.php" > /dev/null ;
}

# Go to the project a tool was asked about, or say why not.
function buddypress_enter_project() {
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}";
  if [ ! -d "${project_path}" ] ; then
    echo "No project ${PROJECT_NAME} in ${WORKSPACE_ROOT}/${doc_name}." ;
    return 1 ;
  fi
  if ! buddypress_is_project "${project_path}" ; then
    echo "${doc_name}/${PROJECT_NAME} is not a community: a WordPress project with BuddyPress in its plugins." ;
    return 1 ;
  fi
  cd "${project_path}" || return 1 ;
}

# The claim of this plugin on a project, in the folder of the container tool: a config overlay with one key the web
# container does not use, the name of the platform the project was built as. The core's tools read the file's name: a
# project that carries config.<plugin>.yaml takes the test users of that plugin.
function buddypress_write_claim() {
  local project_path="$1" ;
  mkdir -p "${project_path}/.ddev" || return 1 ;
  cat > "${project_path}/.ddev/config.buddypress.yaml" <<'YAMLEOF'
# Written by the BuddyPress plugin of the Webship Workspace (cmd-buddypress-project.sh).
#
# It is the plugin's claim on this project: the workspace's tools take the test users of the community for it
# (cmd-tools-add-users.sh <project> buddypress) instead of the WordPress list. The key below is in the environment of
# the web container from its next start; nothing of the site reads it.
web_environment:
  - WEBSHIP_WORKSPACE_PLATFORM=buddypress
YAMLEOF
}

# Run community-site.php in the site, in the project folder: the sample content, a reset, the accounts' names, a
# status, each written or read with the plugin's own functions.
function buddypress_community_site() {
  local script="${WORKSPACE_SCRIPTS}/plugins/buddypress/community-site.php" status ;
  if [ ! -f "${script}" ] ; then
    echo "The BuddyPress plugin's community-site.php is not at ${script}: install the plugin again (plugins.sh --install buddypress)." ;
    return 1 ;
  fi
  cp "${script}" .webship-community-site.php || return 1 ;
  ddev wp eval-file .webship-community-site.php "$@" < /dev/null ;
  status=$? ;
  rm -f .webship-community-site.php ;
  return ${status} ;
}

# Turn on the components a community uses, with the plugin's own command (it makes their tables and pages).
function buddypress_components() {
  local active component ;
  active="$(ddev wp bp component list --status=active --fields=id --format=csv < /dev/null 2>/dev/null)" ;
  for component in ${BUDDYPRESS_COMPONENTS} ; do
    grep -qx "${component}" <<< "${active}" && continue ;
    ddev wp bp component activate "${component}" < /dev/null || return 1 ;
  done
}

# Build a community from nothing: the WordPress plugin's builder makes the site, then BuddyPress is added.
function buddypress_build() {
  trim_project_name ;
  local base_url runtime ;
  runtime="$(buddypress_runtime)" ;
  if [ "${RUNTIME:-_none_}" != '_none_' ] && [ "${RUNTIME}" != "${runtime}" ] ; then
    echo "--runtime ${RUNTIME} needs a Webship Workspace with the container runtimes (webship/workspace#694): update the workspace, or build on DDEV." ;
    exit 1 ;
  fi
  local buddypress_version="${VERSION:-${site_version:-latest}}" ;
  local add_users="${ADD_USERS}" launch="${LAUNCH}" ;

  if ! declare -f wordpress_build > /dev/null ; then
    echo "The BuddyPress plugin builds on the WordPress plugin, which is not installed here:" ;
    echo "  bash core/scripts/plugins.sh --install wordpress" ;
    exit 1 ;
  fi

  # The site, by the WordPress plugin's builder: the container, WordPress, and with --install the site with the
  # workspace account as its administrator. Its --version is WordPress's; the accounts and the browser come after the
  # community is set up.
  VERSION="${WORDPRESS_VERSION:-${wordpress_version:-latest}}" ;
  ADD_USERS='no' ; LAUNCH='no' ;
  ( wordpress_build ) || exit 1 ;
  ADD_USERS="${add_users}" ; LAUNCH="${launch}" ;

  cd "${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}" || exit 1 ;
  # The address is the runtime's to say, now the project is configured: never a written ddev.site.
  base_url="$(buddypress_url)" ;
  # The claim: a file of the container tool's on DDEV, the x-webship block on another runtime.
  if [ "${runtime}" != 'ddev' ] ; then
    rt_claim buddypress || { echo "The plugin's claim on the project could not be written." ; exit 1 ; } ;
  else
    buddypress_write_claim "${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}" || { echo "The plugin's claim on the project could not be written." ; exit 1 ; } ;
  fi

  if [ "${INSTALL}" != 'yes' ] ; then
    # No site yet: BuddyPress goes into the plugins, to activate once WordPress is installed.
    local zip="buddypress.latest-stable.zip" ;
    [ "${buddypress_version}" != 'latest' ] && zip="buddypress.${buddypress_version}.zip" ;
    ddev exec "curl -fsSL https://downloads.wordpress.org/plugin/${zip} -o /tmp/buddypress.zip && unzip -oq /tmp/buddypress.zip -d wp-content/plugins && rm -f /tmp/buddypress.zip" < /dev/null \
      || { echo "BuddyPress could not be downloaded." ; exit 1 ; } ;
    [ "${ADD_USERS}" == 'yes' ] && echo "--add-users needs --install: there is no site to add accounts to yet." ;
    [ "${SAMPLE_CONTENT}" == 'yes' ] && echo "--sample-content needs --install: there is no community to add the content to yet." ;
    echo "${doc_name} ${PROJECT_NAME} is ready to install, with BuddyPress in its plugins.";
    echo "Go to ${base_url}";
    cd ${WORKSPACE_ROOT}/${doc_name};
    return 0 ;
  fi

  # Pretty addresses (the community lives at /members/, /groups/, /activity/), and a registration page that answers.
  ddev wp rewrite structure '/%postname%/' < /dev/null > /dev/null ;
  ddev wp option update users_can_register 1 < /dev/null > /dev/null ;
  ddev wp plugin install buddypress $( [ "${buddypress_version}" != 'latest' ] && echo "--version=${buddypress_version}" ) --activate < /dev/null \
    || { echo "BuddyPress could not be installed." ; exit 1 ; } ;
  # The plugin's own install (its tables, its default components, its mail templates), which a plugin activated from
  # the command line leaves to the first page of the administration: there it would turn off the components below.
  ddev wp eval 'bp_version_updater();' < /dev/null > /dev/null || { echo "BuddyPress could not be set up." ; exit 1 ; } ;
  buddypress_components || { echo "The community's components could not be turned on." ; exit 1 ; } ;

  # The accounts before the content: each sample update, friendship and group is the work of an account.
  if [ "${ADD_USERS}" == 'yes' ] ; then
    set_buddypress_users ;
    add_buddypress_users ;
    cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;
  fi

  if [ "${SAMPLE_CONTENT}" == 'yes' ] ; then
    [ "${ADD_USERS}" == 'yes' ] || echo "Without --add-users the sample content has only the accounts the site has." ;
    buddypress_community_site content || { echo "The sample content could not be added." ; exit 1 ; } ;
  fi

  # The community's addresses answer once the rules are written again: a plugin activated from the command line does
  # not write them.
  ddev wp rewrite flush < /dev/null > /dev/null 2>&1 ;
  echo "${doc_name} ${PROJECT_NAME} has been installed: WordPress $(ddev wp core version 2>/dev/null < /dev/null), BuddyPress $(ddev wp plugin get buddypress --field=version 2>/dev/null < /dev/null).";
  echo "Go to ${base_url}/members/, and ${base_url}/wp-admin as ${account_name}";

  if [ "${LAUNCH}" == 'yes' ] ; then
    ddev launch /members/ ;
  fi

  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Create the default accounts with WP-CLI, each with its role on the site, then give each the name the community shows;
# an account that is already there keeps its password and gets its role and its name back. The list is loaded by the
# caller (set_buddypress_users): the core's add_users, the builder, the community's tool, the testing setup.
function add_buddypress_users() {
  buddypress_enter_project || return 1 ;
  local user user_name user_mail user_password user_role user_fullname ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail";
    user_password="user_${user}_password"; user_role="user_${user}_role"; user_fullname="user_${user}_fullname";

    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo "      User mail: ${!user_mail}";
    echo "  User password: ${!user_password}";
    echo "      User role: ${!user_role}";
    echo "   Display name: ${!user_fullname:-${!user_name}}";
    echo " ================================================================= ";

    if ddev wp user get "${!user_name}" --field=ID < /dev/null > /dev/null 2>&1 ; then
      echo "   ${!user_name} is already there." ;
      ddev wp user set-role "${!user_name}" "${!user_role}" < /dev/null > /dev/null ;
    else
      ddev wp user create "${!user_name}" "${!user_mail}" --role="${!user_role}" --user_pass="${!user_password}" < /dev/null ;
    fi
  done
  # The names the community shows ("Member Test"): its profile field "Name" and the display name, for the accounts of
  # the list that are on the site.
  buddypress_community_site names > /dev/null || echo "   the names could not be set: is BuddyPress active on the site?" ;
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Delete the default accounts. The community removes what was theirs (their updates, friendships, memberships and
# messages); the sample content comes back with the accounts (--add-users, then --sample-content).
function cancel_buddypress_users() {
  buddypress_enter_project || return 1 ;
  local user user_name ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name";
    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo " ================================================================= ";
    if ddev wp user get "${!user_name}" --field=ID < /dev/null > /dev/null 2>&1 ; then
      ddev wp user delete "${!user_name}" --yes < /dev/null ;
    else
      echo "   ${!user_name} is not there." ;
    fi
  done
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# What cmd-tools-buddypress-community.sh does: the first of --add-users, --cancel-users, --sample-content, --tidy that
# was asked for; with none of them, what the community holds.
function buddypress_community_tool() {
  trim_project_name ;
  buddypress_enter_project || exit 1 ;

  if ! ddev wp core is-installed < /dev/null > /dev/null 2>&1 ; then
    ddev start -y < /dev/null || exit 1 ;
  fi
  if ! ddev wp plugin is-active buddypress < /dev/null > /dev/null 2>&1 ; then
    echo "${doc_name}/${PROJECT_NAME}: BuddyPress is not active on the site (is WordPress installed? bash cmd-tools-wordpress-cli.sh ${PROJECT_NAME})." ;
    exit 1 ;
  fi

  if [ "${ADD_USERS}" == 'yes' ] ; then
    set_buddypress_users ;
    add_buddypress_users ;
  elif [ "${CANCEL_USERS}" == 'yes' ] ; then
    set_buddypress_users ;
    cancel_buddypress_users ;
  elif [ "${SAMPLE_CONTENT}" == 'yes' ] ; then
    buddypress_components || exit 1 ;
    buddypress_community_site content || exit 1 ;
    ddev wp rewrite flush < /dev/null > /dev/null 2>&1 ;
  elif [ "${TIDY}" == 'yes' ] ; then
    buddypress_community_site reset || exit 1 ;
    echo "The community is back as the sample content left it." ;
  else
    echo "${doc_name}/${PROJECT_NAME}: BuddyPress $(ddev wp plugin get buddypress --field=version 2>/dev/null < /dev/null) on WordPress $(ddev wp core version 2>/dev/null < /dev/null), at $(ddev wp option get siteurl 2>/dev/null < /dev/null)/members/" ;
    echo "" ;
    buddypress_community_site status || exit 1 ;
  fi
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# The step pack in the testing stack of a community. The core's testing_configure calls this in the project folder
# once webship-js is scaffolded and before the dependencies are installed; for a project without BuddyPress it changes
# nothing.
#
# The community's pack extends the WordPress pack, and both go in the same profile: the WordPress plugin's hook runs
# first (its pack, its users registry, its first feature), whichever order the core calls the hooks in; then this one
# adds its pack to package.json and its step definitions to cucumber.js, the tags that keep its assertions that must
# fail out of a normal run, the mail catcher of the project, the community's handles in the users registry (with the
# addresses the mail steps read and the names the community shows), and a first feature for the community when the
# project has none. Every part is skipped when it is already there, so a second run adds what the first missed and
# never resets a suite.
function testing_configure_buddypress() {
  local project_path="$1";
  buddypress_is_project "${project_path}" || return 0 ;
  if [ ! -f "${project_path}/cucumber.js" ] || [ ! -f "${project_path}/package.json" ] ; then
    echo "  BuddyPress: cucumber.js is not here yet — run the testing setup again once webship-js is scaffolded." ;
    return 1 ;
  fi

  if declare -f testing_configure_wordpress > /dev/null ; then
    testing_configure_wordpress "${project_path}" || return 1 ;
  fi

  echo "Adding the BuddyPress step pack (${BUDDYPRESS_STEPS_PACKAGE} ${BUDDYPRESS_STEPS_VERSION}).";
  set_buddypress_users ;
  local registry="" user user_name user_mail user_password user_fullname handle ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail"; user_password="user_${user}_password"; user_fullname="user_${user}_fullname";
    # The WordPress pack's features call the administrator "admin".
    handle="${user}" ; [ "${user}" == 'administrator' ] && handle="admin" ;
    registry="${registry}${handle}|${!user_name}|${!user_password}|${!user_mail}|${!user_fullname}"$'\n' ;
  done

  python3 - "${project_path}" "${BUDDYPRESS_STEPS_PACKAGE}" "${BUDDYPRESS_STEPS_VERSION}" 'WP' "${registry}" <<'PYEOF' || return 1
import json, re, sys

project, pack, version, prefix, registry = sys.argv[1:6]

# package.json: the pack as a dev dependency, at the release line this plugin was proven on.
pkg_file = project + '/package.json'
pkg = json.load(open(pkg_file))
if pack not in pkg.get('dependencies', {}) and pack not in pkg.get('devDependencies', {}):
    pkg.setdefault('devDependencies', {})[pack] = version
    open(pkg_file, 'w').write(json.dumps(pkg, indent=2) + '\n')
    print('  package.json: %s %s' % (pack, version))

cucumber_file = project + '/cucumber.js'
src = open(cucumber_file).read()
before = src

# The pack's step definitions, after webship-js's own (and the WordPress pack's, which it loads itself).
if ('node_modules/%s/' % pack) not in src:
    line = "'node_modules/%s/tests/step-definitions/**/*.js'," % pack
    anchor = re.search(r"^([ \t]*)'node_modules/@webship-js/wordpress-steps/tests/step-definitions/[^']*',.*$", src, re.M) \
        or re.search(r"^([ \t]*)'node_modules/webship-js/tests/step-definitions/[^']*',.*$", src, re.M)
    opening = re.search(r"^([ \t]*)require:[ \t]*\[[ \t]*$", src, re.M)
    if anchor:
        src = src[:anchor.end()] + '\n' + anchor.group(1) + line + src[anchor.end():]
    elif opening:
        src = src[:opening.end()] + '\n' + opening.group(1) + '  ' + line + src[opening.end():]
    else:
        sys.exit("  cucumber.js has no require list this can add to. Add this line to it:\n    " + line)
    print('  cucumber.js: the step definitions of %s' % pack)

# The pack's assertions that must fail are no part of a normal run.
if not re.search(r"^[ \t]*tags:", src, re.M):
    default = re.search(r"^([ \t]*)default:[ \t]*\{[ \t]*$", src, re.M)
    if default:
        pad = default.group(1) + '  '
        src = src[:default.end()] + '\n' + pad + "// Work in progress and the assertions that must fail (@must-fail) stay out of a normal run.\n" \
            + pad + "tags: process.env.CUCUMBER_TAGS || 'not @wip and not @must-fail'," + src[default.end():]
        print('  cucumber.js: the tags that keep the assertions that must fail out of a normal run')

world = re.search(r"^([ \t]*)worldParameters:[ \t]*\{[ \t]*$", src, re.M)
if not world:
    sys.exit("  cucumber.js has no worldParameters block to add the users registry to.")
pad = world.group(1) + '  '

# The mail catcher of the project: the community's mail is read in it (port 8026 of a DDEV project).
if not re.search(r"^[ \t]*mailUrl:", src, re.M):
    block = pad + "// The mail catcher of the project (the mail steps read it).\n" \
        + pad + "mailUrl: process.env.MAIL_URL || (process.env.LAUNCH_URL || '').replace(/\\/+$/, '') + ':8026',"
    src = src[:world.end()] + '\n' + block + src[world.end():]
    print('  cucumber.js: the mail catcher of the project')
    world = re.search(r"^([ \t]*)worldParameters:[ \t]*\{[ \t]*$", src, re.M)

rows = [r.split('|') for r in registry.splitlines() if r.strip()]
entry = lambda handle, login, password, mail, name: "%s: { username: process.env.%s_%s_USER || '%s', password: process.env.%s_%s_PASSWORD || '%s', email: '%s', name: '%s' }," % (
    handle, prefix, handle.upper(), login, prefix, handle.upper(), password, mail, name)
users = re.search(r"^([ \t]*)users:[ \t]*\{[ \t]*$", src, re.M)
if users:
    # The registry the WordPress plugin wrote: the community's handles it does not have go in at its start, and a
    # handle it has without an address or a name (admin) gets the address the mail steps read and the name the
    # community shows.
    missing = [r for r in rows if not re.search(r"^[ \t]*%s:[ \t]*\{" % re.escape(r[0]), src, re.M)]
    if missing:
        inner = users.group(1) + '  '
        src = src[:users.end()] + '\n' + '\n'.join(inner + entry(*r) for r in missing) + src[users.end():]
        print('  cucumber.js: the community\'s accounts in the users registry (%s)' % ', '.join(r[0] for r in missing))
    for handle, login, password, mail, name in rows:
        line = re.search(r"^([ \t]*%s:[ \t]*\{)([^\n]*)(\},?[ \t]*)$" % re.escape(handle), src, re.M)
        if line and 'email:' not in line.group(2):
            src = src[:line.start()] + line.group(1) + line.group(2).rstrip() + ", email: '%s' " % mail + line.group(3) + src[line.end():]
        line = re.search(r"^([ \t]*%s:[ \t]*\{)([^\n]*)(\},?[ \t]*)$" % re.escape(handle), src, re.M)
        if line and not re.search(r"(?<![A-Za-z_])name:", line.group(2)):
            src = src[:line.start()] + line.group(1) + line.group(2).rstrip() + ", name: '%s' " % name + line.group(3) + src[line.end():]
else:
    block = [
        pad + "// The users registry: a handle a scenario reads, mapped to an account of this site (the default",
        pad + "// accounts: cmd-tools-add-users.sh <project> buddypress). Override one with %s_<HANDLE>_USER and %s_<HANDLE>_PASSWORD." % (prefix, prefix),
        pad + "users: {",
    ] + [pad + '  ' + entry(*r) for r in rows] + [pad + "},"]
    src = src[:world.end()] + '\n' + '\n'.join(block) + src[world.end():]
    print('  cucumber.js: the users registry (%s)' % ', '.join(r[0] for r in rows))

if src != before:
    open(cucumber_file, 'w').write(src)

# The WordPress plugin's first feature says a visitor sees no toolbar; a community shows WordPress's toolbar to its
# visitors too (BuddyPress's "Show the Toolbar for logged-out users", on by default, with its Log In and Register
# links). Its scenario, as that plugin wrote it, gets the community's toolbar; a scenario a person changed is kept.
site_feature = project + '/tests/features/site.feature'
try:
    feature = open(site_feature).read()
except OSError:
    feature = None
if feature:
    old = ("  Scenario: An anonymous visitor has no session\n"
           "    Given I am an anonymous user\n"
           "    And I am on the homepage\n"
           "    Then I should not see the admin bar\n")
    new = ("  # A community shows the toolbar to its visitors too (BuddyPress's \"Show the Toolbar for logged-out users\",\n"
           "  # on by default): its Log In and Register links.\n"
           "  Scenario: An anonymous visitor has no session, and the community's toolbar\n"
           "    Given I am an anonymous user\n"
           "    And I am on the homepage\n"
           "    Then I should see the admin bar\n")
    if old in feature:
        open(site_feature, 'w').write(feature.replace(old, new))
        print("  tests/features/site.feature: a visitor of a community has the toolbar")
PYEOF

  # A first feature for the community, when the project has none: the directories, a profile, each account in its
  # place.
  local feature="${WORKSPACE_SCRIPTS}/plugins/buddypress/community.feature" ;
  if [ -f "${feature}" ] && [ ! -f "${project_path}/tests/features/community.feature" ] ; then
    mkdir -p "${project_path}/tests/features" && cp "${feature}" "${project_path}/tests/features/community.feature" \
      && echo "  tests/features/community.feature: a first feature for the community" ;
  fi

  # The scenarios log in as the default accounts: make sure an installed site has them.
  if ddev wp core is-installed < /dev/null > /dev/null 2>&1 ; then
    ( add_buddypress_users > /dev/null ) && echo "  the community's default accounts are on the site (${users[*]})" ;
  fi
}
