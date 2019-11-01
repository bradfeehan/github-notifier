#!/bin/bash

readonly APP_NAME=$(basename $BASH_SOURCE)
readonly DIR_NAME=$(dirname $BASH_SOURCE)

. $DIR_NAME/lib/config_accessor.sh

function usage() {
cat <<- EOF

Usage:
  $APP_NAME list
  $APP_NAME add <github instance url> [<access token>]
  $APP_NAME rm <github instance url>
  $APP_NAME activate <github instance url>
  $APP_NAME deactivate <github instance url>
  $APP_NAME token update <github instance url> [<new token>]

Normally, the most popular github instance is https://github.com
The other instances are github enterprise instances.

Examples:
   List all configurations:
   $APP_NAME list

   Add a new configuration:
   $APP_NAME add https://github.mycompany.com
   
   Deactivate a configuration:
   $APP_NAME deactivate https://github.mycompany.com

   Remove a configuration:
   $APP_NAME rm https://github.mycompany.com

   Reset token
   $APP_NAME token update github.mycompany.com new_token
EOF
}

function route_command() {
  local cmd=$1
  case $cmd in
    "list")
      list_configs
    ;;
    "add")
      local config_name=$2
      local access_token=$3
      add_config $config_name $access_token
    ;;
    "rm")
      local config_name=$2
      remove_config $config_name
    ;;
    "activate")
      local config_name=$2
      activate_config $config_name
    ;;
    "deactivate")
      local config_name=$2
      deactivate_config $config_name
    ;;
    "token")
      local token_cmd=$2
      local config_name=$3
      local access_token=$4
      route_token_command $token_cmd $config_name $access_token
    ;;
    *)
      if [[ $cmd ]]; then
        echo "unknown command $cmd"
      fi
      usage
    ;;
    esac
}

function route_token_command() {
  local cmd=$1
  local config_name=$2
  local access_token=$3
  case $cmd in
    "update")
      update_token $config_name $access_token
    ;;
    "")
      usage
    ;;
  esac
}

route_command $1 $2 $3 $4
