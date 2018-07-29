#!/bin/bash

APP=github_notif
readonly CURRENT_DIR=`dirname $0`

. $CURRENT_DIR/lib/mock.sh

function mock_request() {
  local url=$1
  if [ "$url" == "https://api.github.com/notifications" ]; then
    cat $CURRENT_DIR/data/list_of_notifications.json
  elif [ "$url" == "https://api.github.com/repos/octokit/octokit.rb/issues/comments/123" ]; then
    cat $CURRENT_DIR/data/notification_details_123.json
  elif [ "$url" == "https://api.github.com/repos/octokit/octokit.rb/issues/comments/124" ]; then
    cat $CURRENT_DIR/data/notification_details_124.json
  elif [ "$url" == "https://api.github.com/repos/octokit/octokit.rb/issues/comments/125" ]; then
    cat $CURRENT_DIR/data/notification_details_125.json
  elif [ "$url" == "https://api.github.com/repos/octokit/octokit.rb/issues/123" ]; then
    cat $CURRENT_DIR/data/issue_notification_details_123.json
  elif [ "$url" == "https://github.com/notifications" ]; then
    cat $CURRENT_DIR/data/list_of_notifications.json
  fi
}

function mock_terminal_notifier() {
  mock terminal_notifier "$@"
}

function mock_failing_remote_call() {
  echo Failed to connect to url;
  return 1
}

function mock_failing_notification_details_call() {
  local url=$1
  if [ "$url" == "https://api.github.com/repos/octokit/octokit.rb/issues/comments/123" ]; then
    echo Failed to connect to https://api.github.com/repos/octokit/octokit.rb/issues/comments/123
    return 1
  else
    mock_request $url
  fi
}

function construct_notification() {
  local title=$1
  local message=$2
  local commit_url=$3
  echo "--group 1 -title $title -subtitle Greetings -message $message -open $commit_url -appIcon $DIR_NAME/logo.png"
}

function mock_show_missed_notifications() {
  echo "new_commit_id"
}

oneTimeSetUp() {
  shopt -s expand_aliases
  alias terminal-notifier=mock_terminal_notifier
  alias do_github_remote_call=mock_request

  HOME=$SHUNIT_TMPDIR
  source $APP > /dev/null
  KEEP_IN_SCREEN_TIME_IN_SECONDS=0

  readonly COMMIT1=$(construct_notification "pengwynn commented on an issue in Hello-World" "The first commit" https://github.com/octokit/octokit.rb/pull/123#issuecomment-7627180)
  readonly COMMIT2=$(construct_notification "pengwynn commented on an issue in Hello-World" "The second commit" https://github.com/octokit/octokit.rb/pull/123#issuecomment-7627180)
  readonly COMMIT3=$(construct_notification "dlackty created an issue in Hello-World" "As titled. (Ref: #118.) Please help review and let me know if there is a problem. Thanks!" \
  https://github.com/octokit/octokit.rb/pull/123)
  #Todo: handle dates
  readonly MORE_THAN_ONE_MISSED_COMMITS_PATTERN="--group 1 -title Missed notifications on github.com -subtitle
  .*-message See all -open https://github.com/notifications -appIcon $DIR_NAME/logo.png"
  readonly NOTIFICATIONS_JSON=$(cat $CURRENT_DIR/data/list_of_notifications.json)
}

test_show_notification() {
  show_notification token "$NOTIFICATIONS_JSON" 0
  verify_with_all_args terminal_notifier "$COMMIT1"
}

test_show_notification_on_null_latest_commit_id() {
  show_notification token "$NOTIFICATIONS_JSON" 3
  verify_with_all_args terminal_notifier "$COMMIT3"
}

test_show_all_notifications() {
  show_all_notifications https://github.com
  verify_with_arg_pattern terminal_notifier $MORE_THAN_ONE_MISSED_COMMITS_PATTERN
}

test_show_missed_notifications_when_no_notification() {
  local shown_id=5
  local result=$(show_missed_notifications https://github.com token "[]" $shown_id)
  assertEquals "5" "$result"
}

test_show_missed_notifications_on_total_one_notification() {
  local shown_id=5
  local one_notification=$(echo "$NOTIFICATIONS_JSON" | $JQ .[0])
  show_missed_notifications https://github.com token "[$one_notification]" $shown_id > $SHUNIT_TMPDIR/last_shown_id
  assertEquals "3" $(cat $SHUNIT_TMPDIR/last_shown_id)
  verify_with_all_args terminal_notifier "$COMMIT1"
}

test_show_missed_notifications_on_total_two_notifications() {
  local shown_id=5
  local first_notification=$(echo "$NOTIFICATIONS_JSON" | $JQ .[0])
  local second_notification=$(echo "$NOTIFICATIONS_JSON" | $JQ .[1])
  show_missed_notifications https://github.com token "[$first_notification, $second_notification]" $shown_id > $SHUNIT_TMPDIR/last_shown_id
  assertEquals "3" $(cat $SHUNIT_TMPDIR/last_shown_id)
  verify_with_all_args terminal_notifier "$COMMIT1"
  verify_with_all_args terminal_notifier "$COMMIT2"
}

test_show_missed_notifications_when_no_new_notification() {
  local shown_id=3
  local last_shown_id=$(show_missed_notifications https://github.com token "$NOTIFICATIONS_JSON" $shown_id)
  assertEquals "3" "$last_shown_id"
}

test_show_missed_notifications_on_one_new_notification() {
  local shown_id=2
  show_missed_notifications https://github.com token "$NOTIFICATIONS_JSON" $shown_id > $SHUNIT_TMPDIR/last_shown_id
  assertEquals "3" $(cat $SHUNIT_TMPDIR/last_shown_id)
  verify_with_all_args terminal_notifier "$COMMIT1"
}

test_show_missed_notifications_on_two_new_notifications() {
  local shown_id=1
  show_missed_notifications https://github.com token "$NOTIFICATIONS_JSON" $shown_id > $SHUNIT_TMPDIR/last_shown_id
  assertEquals "3" $(cat $SHUNIT_TMPDIR/last_shown_id)
  verify_with_all_args terminal_notifier "$COMMIT1"
  verify_with_all_args terminal_notifier "$COMMIT2"
}

test_show_missed_notifications_on_more_than_two_notifications() {
  local shown_id=0
  show_missed_notifications https://github.com token "$NOTIFICATIONS_JSON" $shown_id > $SHUNIT_TMPDIR/last_shown_id
  assertEquals "3" $(cat $SHUNIT_TMPDIR/last_shown_id)
  verify_with_all_args terminal_notifier "$COMMIT1"
  verify_with_all_args terminal_notifier "$COMMIT2"
  verify_with_arg_pattern terminal_notifier $MORE_THAN_ONE_MISSED_COMMITS_PATTERN
}

test_show_missed_notifications_on_failing_notification_details_call() {
  alias do_github_remote_call=mock_failing_notification_details_call
  local shown_id=0
  show_missed_notifications https://github.com token "$NOTIFICATIONS_JSON" $shown_id > $SHUNIT_TMPDIR/last_shown_id
  assertEquals 1 $?
  verify_with_all_args terminal_notifier "$COMMIT2"
  verify_with_arg_pattern terminal_notifier $MORE_THAN_ONE_MISSED_COMMITS_PATTERN
}

test_show_notifications_on_missing_active_configs() {
  alias get_active_configs=
  local error=$(main)
  assertEquals 'There is no any active configuration to get notifications' "$error"
}

test_show_notifications_on_multiple_active_config() {
  alias get_active_configs="echo config1 config2"
  alias show_missed_notifications=mock_show_missed_notifications
  local error=$(main)
  assertEquals '' "$error"
  assertEquals "new_commit_id" "$(get_last_shown_commit_id config1)"
  assertEquals "new_commit_id" "$(get_last_shown_commit_id config2)"
}

test_show_notifications_on_multiple_active_config_when_connections_fails() {
  alias do_github_remote_call=mock_failing_remote_call
  alias get_active_configs="echo config1 config2"
  local error=$(main)
  assertTrue 'The error log is wrong' '[[ "$(echo "$error" | head -n 1)" == *"Failed to connect to url" ]]'
  assertTrue 'The error log is wrong' '[[ "$(echo "$error" | tail -n 1)" == *"Failed to connect to url" ]]'
}

. shunit2
