<?php
/**
 * The community of the test site: its components and settings, the accounts' places and the test content.
 *
 * Run inside the site with WP-CLI, once the community plugin is active:
 *
 *   wp eval-file community-site.php              the accounts' places and the content (what is there already is
 *                                                kept); the build turns the components on first (wp bp component)
 *   wp eval-file community-site.php content      the same
 *   wp eval-file community-site.php reset        put the community back as the build left it: what a stopped run left
 *                                                behind goes ("Webship test …"), the friendships, the memberships and
 *                                                the profile fields of the accounts come back
 *   wp eval-file community-site.php names        only the names the community shows for the accounts
 *   wp eval-file community-site.php status       say what the community holds
 *   wp eval-file community-site.php counts       the counts a test run must leave as it found them (CI compares them)
 *
 * Everything is made with the plugin's own functions (groups_create_group, friends_add_friend, bp_activity_post_update,
 * messages_new_message, xprofile_set_field_data), so the counts, the notifications and the "last active" of every
 * member and group are the ones the plugin keeps. No account is created here: the build creates them.
 */

if ( ! function_exists( 'buddypress' ) ) {
	fwrite( STDERR, "The community plugin is not active on this site.\n" );
	exit( 1 );
}
foreach ( array( 'xprofile', 'activity', 'friends', 'groups', 'messages' ) as $webship_component ) {
	if ( ! bp_is_active( $webship_component ) ) {
		fwrite( STDERR, "The component {$webship_component} is off: wp bp component activate {$webship_component}.\n" );
		exit( 1 );
	}
}

$webship_mode = isset( $args[0] ) ? $args[0] : 'all';
// The reset puts the build's friendships and memberships back without the stream items, notifications and mails a person's
// actions make.
$GLOBALS['webship_quiet'] = false;

/** The administrator the command line works as: the first administrator of the site. */
function webship_admin_id() {
	$admins = get_users( array( 'role' => 'administrator', 'orderby' => 'ID', 'order' => 'ASC', 'number' => 1, 'fields' => 'ID' ) );
	return $admins ? (int) $admins[0] : 1;
}

/** The accounts of the suite by login, and their names. An account that is not on the site is skipped. */
function webship_accounts() {
	return array(
		'administrator' => 'Administrator Test',
		'organizer'     => 'Organizer Test',
		'moderator'     => 'Moderator Test',
		'member'        => 'Member Test',
		'newcomer'      => 'Newcomer Test',
	);
}

function webship_user_id( $login ) {
	$user = get_user_by( 'login', $login );
	return $user ? (int) $user->ID : 0;
}

/** The profile fields beside "Name": by name, their group, type, options and the value of each account. */
function webship_fields() {
	return array(
		'Location' => array( 'group' => 'Base', 'type' => 'textbox', 'description' => 'Where you work from.', 'values' => array(
			'organizer' => 'Amman', 'moderator' => 'Lisbon', 'member' => 'Nairobi', 'newcomer' => 'Montreal', 'administrator' => 'Online',
		) ),
		'About me' => array( 'group' => 'Base', 'type' => 'textarea', 'description' => 'A few words about you.', 'values' => array(
			'organizer' => 'I run the groups of this community.',
			'moderator' => 'I keep the club friendly.',
			'member'    => 'Designer and writer, here for the club.',
		) ),
		'Skills'   => array( 'group' => 'Work', 'type' => 'checkbox', 'options' => array( 'Design', 'Development', 'Writing' ), 'values' => array(
			'organizer' => array( 'Design', 'Writing' ), 'moderator' => array( 'Development' ), 'member' => array( 'Design' ),
		) ),
		'Website'  => array( 'group' => 'Work', 'type' => 'url', 'description' => 'A page about your work.', 'values' => array(
			'organizer' => 'https://example.com/organizer',
		) ),
	);
}

function webship_field_group_id( $name ) {
	foreach ( bp_xprofile_get_groups( array( 'fetch_fields' => false ) ) as $group ) {
		if ( $group->name === $name ) {
			return (int) $group->id;
		}
	}
	if ( 'Base' === $name ) {
		return 1;
	}
	$id = xprofile_insert_field_group( array( 'name' => $name, 'description' => 'What you do.', 'can_delete' => true ) );
	echo "  profile field group {$name}\n";
	return (int) $id;
}

function webship_profile_fields() {
	foreach ( webship_fields() as $name => $field ) {
		$id = (int) xprofile_get_field_id_from_name( $name );
		if ( ! $id ) {
			$id = (int) xprofile_insert_field( array(
				'field_group_id' => webship_field_group_id( $field['group'] ),
				'name'           => $name,
				'type'           => $field['type'],
				'description'    => isset( $field['description'] ) ? $field['description'] : '',
				'is_required'    => false,
				'can_delete'     => true,
			) );
			foreach ( isset( $field['options'] ) ? $field['options'] : array() as $order => $option ) {
				xprofile_insert_field( array(
					'field_group_id' => webship_field_group_id( $field['group'] ),
					'parent_id'      => $id,
					'type'           => 'option',
					'name'           => $option,
					'option_order'   => $order + 1,
				) );
			}
			bp_xprofile_update_field_meta( $id, 'default_visibility', 'public' );
			bp_xprofile_update_field_meta( $id, 'allow_custom_visibility', 'allowed' );
			echo "  profile field {$name}\n";
		}
	}
}

/** The names and the profile values of the accounts, as the build left them. */
function webship_profile_values() {
	foreach ( webship_accounts() as $login => $name ) {
		$user_id = webship_user_id( $login );
		if ( ! $user_id ) {
			continue;
		}
		wp_update_user( array( 'ID' => $user_id, 'display_name' => $name, 'first_name' => strtok( $name, ' ' ), 'last_name' => 'Test' ) );
		xprofile_set_field_data( 1, $user_id, $name );
		foreach ( webship_fields() as $field => $data ) {
			$value = isset( $data['values'][ $login ] ) ? $data['values'][ $login ] : '';
			xprofile_set_field_data( $field, $user_id, $value );
		}
		// Who may see each field: the field's default again (a scenario changes one and changes it back).
		bp_delete_user_meta( $user_id, 'bp_xprofile_visibility_levels' );
		bp_update_user_last_activity( $user_id, bp_core_current_time() );
	}
}

/** Only the names the community shows for the accounts ("Member Test"): the accounts made without the sample content. */
function webship_names() {
	foreach ( webship_accounts() as $login => $name ) {
		$user_id = webship_user_id( $login );
		if ( $user_id ) {
			wp_update_user( array( 'ID' => $user_id, 'display_name' => $name, 'first_name' => strtok( $name, ' ' ), 'last_name' => 'Test' ) );
			xprofile_set_field_data( 1, $user_id, $name );
			echo "  {$login}: {$name}\n";
		}
	}
}

/** The friendships of the build: the organizer, the moderator and the member are friends; the newcomer has none. */
function webship_friendships() {
	return array( array( 'organizer', 'member' ), array( 'organizer', 'moderator' ), array( 'moderator', 'member' ) );
}

function webship_set_friendships() {
	$keep = array();
	foreach ( webship_friendships() as $pair ) {
		list( $a, $b ) = array( webship_user_id( $pair[0] ), webship_user_id( $pair[1] ) );
		if ( ! $a || ! $b ) {
			continue;
		}
		$keep[] = "{$a}-{$b}";
		$keep[] = "{$b}-{$a}";
		$status = BP_Friends_Friendship::check_is_friend( $a, $b );
		if ( 'is_friend' !== $status ) {
			if ( 'not_friends' !== $status ) {
				$pending = BP_Friends_Friendship::get_friendship_id( $a, $b );
				if ( $pending ) {
					( new BP_Friends_Friendship( $pending ) )->delete();
				}
			}
			if ( $GLOBALS['webship_quiet'] ) {
				// Back as the build left it, without a stream item, a notification or a mail.
				$friendship                    = new BP_Friends_Friendship();
				$friendship->initiator_user_id = $a;
				$friendship->friend_user_id    = $b;
				$friendship->is_confirmed      = 1;
				$friendship->is_limited        = 0;
				$friendship->date_created      = bp_core_current_time();
				$friendship->save();
				friends_update_friend_totals( $a, $b );
			} else {
				friends_add_friend( $a, $b, true );
			}
			echo "  friends: {$pair[0]} and {$pair[1]}\n";
		}
	}
	// Any other friendship or request between the accounts goes.
	$ids = array_filter( array_map( 'webship_user_id', array_keys( webship_accounts() ) ) );
	foreach ( $ids as $a ) {
		foreach ( $ids as $b ) {
			if ( $a < $b && ! in_array( "{$a}-{$b}", $keep, true ) && 'not_friends' !== BP_Friends_Friendship::check_is_friend( $a, $b ) ) {
				friends_remove_friend( $a, $b );
				$friendship_id = BP_Friends_Friendship::get_friendship_id( $a, $b );
				if ( $friendship_id ) {
					( new BP_Friends_Friendship( $friendship_id ) )->delete();
				}
				echo "  a friendship or a request between {$a} and {$b}: removed\n";
			}
		}
	}
}

/** The groups of the build, by slug: name, status, description, administrator, moderators and members. */
function webship_groups() {
	return array(
		'webship-club'  => array( 'name' => 'Webship Club', 'status' => 'public', 'description' => 'The open club of the community: news, questions and the work of its members.', 'admins' => array( 'organizer' ), 'mods' => array( 'moderator' ), 'members' => array( 'member' ) ),
		'design-circle' => array( 'name' => 'Design Circle', 'status' => 'private', 'description' => 'A private circle for design reviews: ask to join.', 'admins' => array( 'organizer' ), 'mods' => array(), 'members' => array( 'member' ) ),
		'core-team'     => array( 'name' => 'Core Team', 'status' => 'hidden', 'description' => 'The team that runs the community.', 'admins' => array( 'organizer' ), 'mods' => array(), 'members' => array( 'administrator' ) ),
	);
}

function webship_set_groups() {
	foreach ( webship_groups() as $slug => $group ) {
		$creator  = webship_user_id( $group['admins'][0] ) ?: webship_admin_id();
		$group_id = (int) groups_get_id( $slug );
		if ( ! $group_id ) {
			$group_id = (int) groups_create_group( array(
				'creator_id'   => $creator,
				'name'         => $group['name'],
				'slug'         => $slug,
				'description'  => $group['description'],
				'status'       => $group['status'],
				'enable_forum' => 0,
				'date_created' => bp_core_current_time(),
			) );
			groups_update_groupmeta( $group_id, 'invite_status', 'members' );
			groups_update_groupmeta( $group_id, 'last_activity', bp_core_current_time() );
			echo "  group {$group['name']} ({$group['status']})\n";
		} else {
			groups_edit_base_group_details( array( 'group_id' => $group_id, 'name' => $group['name'], 'slug' => $slug, 'description' => $group['description'], 'notify_members' => false ) );
			groups_edit_group_settings( $group_id, 0, $group['status'], 'members' );
		}
		$wanted = array();
		foreach ( array( 'admin' => $group['admins'], 'mod' => $group['mods'], 'member' => $group['members'] ) as $place => $logins ) {
			foreach ( $logins as $login ) {
				$user_id = webship_user_id( $login );
				if ( ! $user_id ) {
					continue;
				}
				$wanted[ $user_id ] = $place;
				if ( ! groups_is_user_member( $user_id, $group_id ) ) {
					if ( $GLOBALS['webship_quiet'] ) {
						BP_Groups_Member::delete( $user_id, $group_id );
						$membership                = new BP_Groups_Member();
						$membership->group_id      = $group_id;
						$membership->user_id       = $user_id;
						$membership->inviter_id    = 0;
						$membership->is_admin      = 0;
						$membership->user_title    = '';
						$membership->date_modified = bp_core_current_time();
						$membership->is_confirmed  = 1;
						$membership->comments      = '';
						$membership->invite_sent   = 0;
						$membership->save();
					} else {
						groups_join_group( $group_id, $user_id );
					}
					echo "  {$login}: back in {$group['name']}\n";
				}
				// The membership's own methods: the group functions ask for an administrator of the group on a page of it.
				$membership = new BP_Groups_Member( $user_id, $group_id );
				if ( $membership->is_banned ) {
					$membership->unban();
					$membership = new BP_Groups_Member( $user_id, $group_id );
				}
				$is = $membership->is_admin ? 'admin' : ( $membership->is_mod ? 'mod' : 'member' );
				if ( $is !== $place ) {
					if ( 'member' !== $is ) {
						$membership->demote();
						$membership = new BP_Groups_Member( $user_id, $group_id );
					}
					if ( 'member' !== $place ) {
						$membership->promote( $place );
					}
					echo "  {$login}: {$place} of {$group['name']}\n";
				}
			}
		}
		groups_update_groupmeta( $group_id, 'total_member_count', BP_Groups_Group::get_total_member_count( $group_id ) );
		// The suite's accounts that are not of the group leave it, and their requests and invitations go.
		foreach ( array_keys( webship_accounts() ) as $login ) {
			$user_id = webship_user_id( $login );
			if ( ! $user_id || isset( $wanted[ $user_id ] ) ) {
				continue;
			}
			if ( groups_is_user_member( $user_id, $group_id ) || groups_is_user_banned( $user_id, $group_id ) ) {
				BP_Groups_Member::delete( $user_id, $group_id );
				groups_update_groupmeta( $group_id, 'total_member_count', BP_Groups_Group::get_total_member_count( $group_id ) );
				echo "  {$login}: out of {$group['name']}\n";
			}
			groups_delete_membership_request( null, $user_id, $group_id );
			groups_delete_invite( $user_id, $group_id );
		}
	}
}

/** The updates of the build, by a key: who wrote them, where, and the comments and favorites they got. */
function webship_updates() {
	return array(
		'welcome' => array( 'by' => 'organizer', 'content' => 'Welcome to the Webship Community! Say hello, find the club and the circle, and ask anything.', 'comments' => array( array( 'member', 'Hello everyone, glad to be here.' ) ), 'favorites' => array( 'member' ) ),
		'release' => array( 'by' => 'member', 'content' => 'The new pattern library is out: buttons, cards and forms, all in one place.', 'comments' => array(), 'favorites' => array() ),
		'club'    => array( 'by' => 'moderator', 'group' => 'webship-club', 'content' => 'Club meeting on Thursday: bring one thing you made this month.', 'comments' => array(), 'favorites' => array() ),
	);
}

function webship_find_update( $content ) {
	$found = bp_activity_get( array( 'search_terms' => $content, 'display_comments' => false, 'show_hidden' => true, 'per_page' => 1 ) );
	return empty( $found['activities'] ) ? 0 : (int) $found['activities'][0]->id;
}

function webship_set_updates() {
	$wanted = array();
	$fans   = array();
	foreach ( webship_updates() as $key => $update ) {
		$user_id = webship_user_id( $update['by'] ) ?: webship_admin_id();
		$id      = webship_find_update( $update['content'] );
		if ( ! $id ) {
			if ( isset( $update['group'] ) ) {
				$id = (int) groups_post_update( array( 'content' => $update['content'], 'user_id' => $user_id, 'group_id' => (int) groups_get_id( $update['group'] ) ) );
			} else {
				$id = (int) bp_activity_post_update( array( 'content' => $update['content'], 'user_id' => $user_id ) );
			}
			echo "  update {$key} by {$update['by']}\n";
			foreach ( $update['comments'] as $comment ) {
				bp_activity_new_comment( array( 'activity_id' => $id, 'content' => $comment[1], 'user_id' => webship_user_id( $comment[0] ) ) );
			}
		}
		foreach ( $update['favorites'] as $login ) {
			$wanted[ $login ][] = $id;
		}
		$fans[ $id ] = count( $update['favorites'] );
	}
	// Each account's favorites are the build's, and each update counts its own.
	foreach ( array_keys( webship_accounts() ) as $login ) {
		$user_id = webship_user_id( $login );
		if ( $user_id ) {
			bp_update_user_meta( $user_id, 'bp_favorite_activities', isset( $wanted[ $login ] ) ? $wanted[ $login ] : array() );
		}
	}
	foreach ( $fans as $id => $count ) {
		bp_activity_update_meta( $id, 'favorite_count', $count );
	}
}

/** The private message of the build: the organizer welcomes the member. */
function webship_set_messages() {
	$from = webship_user_id( 'organizer' );
	$to   = webship_user_id( 'member' );
	if ( ! $from || ! $to ) {
		return;
	}
	global $wpdb;
	$table = buddypress()->messages->table_name_messages;
	$found = (int) $wpdb->get_var( $wpdb->prepare( "SELECT COUNT(*) FROM {$table} WHERE sender_id = %d AND subject = %s", $from, 'Welcome to the club' ) );
	if ( ! $found ) {
		messages_new_message( array( 'sender_id' => $from, 'recipients' => array( $to ), 'subject' => 'Welcome to the club', 'content' => 'Hi Member, welcome! The club meets on Thursdays; the circle reviews designs on Mondays.' ) );
		echo "  message: Welcome to the club, from organizer to member\n";
	} else {
		$thread_id = (int) $wpdb->get_var( $wpdb->prepare( "SELECT thread_id FROM {$table} WHERE sender_id = %d AND subject = %s ORDER BY id LIMIT 1", $from, 'Welcome to the club' ) );
		$recipients = buddypress()->messages->table_name_recipients;
		$wpdb->query( $wpdb->prepare( "UPDATE {$recipients} SET is_deleted = 0 WHERE thread_id = %d", $thread_id ) );
		$wpdb->query( $wpdb->prepare( "UPDATE {$recipients} SET unread_count = 1 WHERE thread_id = %d AND user_id = %d", $thread_id, $to ) );
		wp_cache_flush();
	}
}

/** The notifications of the build, unread again (a scenario reads them). */
function webship_unread_notifications() {
	global $wpdb;
	$bp   = buddypress();
	$mark = get_option( 'webship_community_built', array() );
	if ( ! empty( $mark['notification'] ) ) {
		$wpdb->query( $wpdb->prepare( "UPDATE {$bp->notifications->table_name} SET is_new = 1 WHERE id <= %d", $mark['notification'] ) );
	}
}

/** The newest item of each kind the build made: what came after it is a run's (the reset removes it). */
function webship_mark_built() {
	global $wpdb;
	$bp = buddypress();
	$mark = array(
		'activity'     => (int) $wpdb->get_var( "SELECT MAX(id) FROM {$bp->activity->table_name}" ),
		'notification' => (int) $wpdb->get_var( "SELECT MAX(id) FROM {$bp->notifications->table_name}" ),
		'message'      => (int) $wpdb->get_var( "SELECT MAX(id) FROM {$bp->messages->table_name_messages}" ),
	);
	update_option( 'webship_community_built', $mark, false );
}

/**
 * What a stopped run left behind: every update, comment and stream item, notification and message that came after the
 * build, and the groups and message threads of the suite ("Webship test …").
 */
function webship_remove_test_content() {
	global $wpdb;
	$bp   = buddypress();
	$mark = get_option( 'webship_community_built', array() );
	if ( ! empty( $mark['activity'] ) ) {
		foreach ( $wpdb->get_col( $wpdb->prepare( "SELECT id FROM {$bp->activity->table_name} WHERE id > %d ORDER BY id DESC", $mark['activity'] ) ) as $id ) {
			bp_activity_delete( array( 'id' => (int) $id ) );
		}
	}
	if ( ! empty( $mark['notification'] ) ) {
		$wpdb->query( $wpdb->prepare( "DELETE FROM {$bp->notifications->table_name} WHERE id > %d", $mark['notification'] ) );
	}
	if ( ! empty( $mark['message'] ) ) {
		foreach ( $wpdb->get_col( $wpdb->prepare( "SELECT DISTINCT thread_id FROM {$bp->messages->table_name_messages} WHERE id > %d", $mark['message'] ) ) as $thread_id ) {
			$first = (int) $wpdb->get_var( $wpdb->prepare( "SELECT MIN(id) FROM {$bp->messages->table_name_messages} WHERE thread_id = %d", $thread_id ) );
			if ( $first > $mark['message'] ) {
				// A thread a run began: gone for every side.
				$wpdb->query( $wpdb->prepare( "DELETE FROM {$bp->messages->table_name_recipients} WHERE thread_id = %d", $thread_id ) );
				$wpdb->query( $wpdb->prepare( "DELETE FROM {$bp->messages->table_name_messages} WHERE thread_id = %d", $thread_id ) );
			} else {
				// A reply a run wrote in a thread of the build: the reply goes.
				$wpdb->query( $wpdb->prepare( "DELETE FROM {$bp->messages->table_name_messages} WHERE thread_id = %d AND id > %d", $thread_id, $mark['message'] ) );
				$wpdb->query( $wpdb->prepare( "UPDATE {$bp->messages->table_name_recipients} SET is_deleted = 0 WHERE thread_id = %d", $thread_id ) );
			}
		}
	}
	foreach ( bp_activity_get( array( 'search_terms' => 'Webship test', 'display_comments' => 'stream', 'show_hidden' => true, 'per_page' => 200 ) )['activities'] as $activity ) {
		bp_activity_delete( array( 'id' => $activity->id ) );
		echo "  update {$activity->id}: removed\n";
	}
	foreach ( groups_get_groups( array( 'search_terms' => 'Webship test', 'show_hidden' => true, 'per_page' => 100 ) )['groups'] as $group ) {
		groups_delete_group( $group->id );
		echo "  group {$group->name}: removed\n";
	}
	$threads = $wpdb->get_col( "SELECT DISTINCT thread_id FROM {$bp->messages->table_name_messages} WHERE subject LIKE 'Webship test%'" );
	foreach ( $threads as $thread_id ) {
		BP_Messages_Thread::delete( (int) $thread_id );
		$wpdb->query( $wpdb->prepare( "DELETE FROM {$bp->messages->table_name_recipients} WHERE thread_id = %d", $thread_id ) );
		$wpdb->query( $wpdb->prepare( "DELETE FROM {$bp->messages->table_name_messages} WHERE thread_id = %d", $thread_id ) );
		echo "  message thread {$thread_id}: removed\n";
	}
}

function webship_status() {
	foreach ( webship_accounts() as $login => $name ) {
		$user_id = webship_user_id( $login );
		if ( ! $user_id ) {
			echo "{$login}: not on the site\n";
			continue;
		}
		$friends = array_map( function ( $id ) { return get_userdata( $id )->user_login; }, (array) friends_get_friend_user_ids( $user_id ) );
		$groups  = array();
		foreach ( webship_groups() as $slug => $group ) {
			$group_id = (int) groups_get_id( $slug );
			if ( $group_id && groups_is_user_member( $user_id, $group_id ) ) {
				$groups[] = $group['name'] . ( groups_is_user_admin( $user_id, $group_id ) ? ' (organizer)' : ( groups_is_user_mod( $user_id, $group_id ) ? ' (moderator)' : '' ) );
			}
		}
		echo "{$login} ({$name}): friends " . ( $friends ? implode( ', ', $friends ) : 'none' ) . '; groups ' . ( $groups ? implode( ', ', $groups ) : 'none' ) . "\n";
	}
	$updates = bp_activity_get( array( 'per_page' => 50, 'display_comments' => false, 'show_hidden' => true ) );
	echo 'updates: ' . count( $updates['activities'] ) . "\n";
}

/**
 * What a run must leave as it found it, one count a line, the same on every run of the same site: the activity by type
 * (hidden items and comments included; last_activity is one row a member, updated in place), each account's
 * notifications (and how many unread), unread messages, friends, groups and favorites, and each group's members. CI
 * compares it before and after the suite.
 */
function webship_counts() {
	global $wpdb;
	$bp = buddypress();
	$lines = array();
	$lines[] = 'activity: ' . (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$bp->activity->table_name}" );
	foreach ( $wpdb->get_results( "SELECT type, COUNT(*) AS n FROM {$bp->activity->table_name} GROUP BY type ORDER BY type" ) as $row ) {
		$lines[] = "activity {$row->type}: {$row->n}";
	}
	foreach ( array_keys( webship_accounts() ) as $login ) {
		$user_id = webship_user_id( $login );
		if ( ! $user_id ) {
			$lines[] = "{$login}: not on the site";
			continue;
		}
		$notifications = (int) $wpdb->get_var( $wpdb->prepare( "SELECT COUNT(*) FROM {$bp->notifications->table_name} WHERE user_id = %d", $user_id ) );
		$unread        = (int) $wpdb->get_var( $wpdb->prepare( "SELECT COUNT(*) FROM {$bp->notifications->table_name} WHERE user_id = %d AND is_new = 1", $user_id ) );
		$lines[] = "{$login} notifications: {$notifications} ({$unread} unread)";
		$lines[] = "{$login} unread messages: " . (int) BP_Messages_Thread::get_inbox_count( $user_id );
		$lines[] = "{$login} friends: " . count( (array) friends_get_friend_user_ids( $user_id ) ) . ' (total_friend_count ' . (int) bp_get_user_meta( $user_id, 'total_friend_count', true ) . ')';
		$groups = (int) $wpdb->get_var( $wpdb->prepare( "SELECT COUNT(*) FROM {$bp->groups->table_name_members} WHERE user_id = %d AND is_confirmed = 1 AND is_banned = 0", $user_id ) );
		$lines[] = "{$login} groups: {$groups} (total_group_count " . (int) bp_get_user_meta( $user_id, 'total_group_count', true ) . ')';
		$lines[] = "{$login} favorites: " . count( (array) bp_activity_get_user_favorites( $user_id ) );
	}
	foreach ( webship_groups() as $slug => $group ) {
		$group_id = (int) groups_get_id( $slug );
		if ( ! $group_id ) {
			$lines[] = "group {$slug}: not on the site";
			continue;
		}
		$members = (int) $wpdb->get_var( $wpdb->prepare( "SELECT COUNT(*) FROM {$bp->groups->table_name_members} WHERE group_id = %d AND is_confirmed = 1 AND is_banned = 0", $group_id ) );
		$lines[] = "group {$slug}: {$members} members (total_member_count " . (int) groups_get_groupmeta( $group_id, 'total_member_count' ) . ')';
	}
	echo implode( "\n", $lines ) . "\n";
}

wp_set_current_user( webship_admin_id() );

switch ( $webship_mode ) {
	case 'all':
	case 'content':
		webship_profile_fields();
		webship_profile_values();
		webship_set_friendships();
		webship_set_groups();
		webship_set_updates();
		webship_set_messages();
		webship_mark_built();
		break;
	case 'reset':
		$GLOBALS['webship_quiet'] = true;
		webship_remove_test_content();
		webship_profile_values();
		webship_set_friendships();
		webship_set_groups();
		webship_set_updates();
		webship_set_messages();
		webship_unread_notifications();
		// An update of the build a run deleted is made again: the new mark keeps it.
		webship_mark_built();
		break;
	case 'names':
		webship_names();
		break;
	case 'status':
		webship_status();
		break;
	case 'counts':
		webship_counts();
		break;
	default:
		fwrite( STDERR, "Unknown mode {$webship_mode}: content, reset, names, status or counts.\n" );
		exit( 1 );
}
