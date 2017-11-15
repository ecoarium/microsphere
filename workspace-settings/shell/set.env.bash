#!/usr/bin/env bash

export APPLICATION_SHORT_VERSION_PREFIX="1.0."
export APPLICATION_LONG_VERSION_PREFIX="${APPLICATION_SHORT_VERSION_PREFIX}0."

export GROUP_ID_BASE='com.jayflowers'
export ARTIFACT_ID_BASE='microsphere'

export RUBY_VERSION=2.2.4

export PATH=/usr/local/packer:$PATH

export VAGRANT_BOXES_CENTOS_NAME='centos-6.7'
export VAGRANT_BOXES_CENTOS_VERSION='1.0.14.next'

export VAGRANT_BOXES_WINDOWS_NAME='windows-10'
export VAGRANT_BOXES_WINDOWS_VERSION='14.14393'

export VAGRANT_BOXES_OSX_NAME='osx-10.11.3'
export VAGRANT_BOXES_OSX_VERSION='1.0.0.next'


function after_bootstrap(){
  arm_timebombs
}

function after_workspace_settings(){
  become_data_bag_manager
  _rake_complete
}

function become_ecosystem_manager(){
  export HATS=$HATS:ecosystem
}

function resign_as_ecosystem_manager(){
  export HATS=${HATS/:ecosystem/}
}

function become_data_bag_manager(){
  export HATS=$HATS:data_bag
}

function resign_as_data_bag_manager(){
  export HATS=${HATS/:data_bag/}
}

function become_ecoarium_cookbook_developer(){
  #become_github_manager
  export HATS=$HATS:ecoarium-cookbooks
}

function resign_as_ecoarium_cookbook_developer(){
  #resign_from_github_management
  export HATS=${HATS/:ecoarium-cookbooks/}
}

function _rspec() {
  bundle 'install' '--local'

  set_workspace_settings_to_fake

  "$(gem_bin_path 'rspec-core' 'rspec')" "$@"
  local exit_code=$?

  eval "${WORKSPACE_SETTINGS_FUNCTION_PREFIX}${WORKSPACE_SETTING}"
  return $exit_code
}

function _rspec_by_func_name() {
  local slack_gem="${FUNCNAME[1]/rspec_/}"

  cd "${PATHS_PROJECT_DEPLOY_HOME}/ruby/$slack_gem"

  _rspec "$@"
  local exit_code=$?

  cd $OLDPWD
  fail_if "rspec failed: rspec ${*}" $exit_code
}
