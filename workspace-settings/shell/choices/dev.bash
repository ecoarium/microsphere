#!/usr/bin/env bash

register_workspace_setting 'dev'

function set_workspace_settings_to_dev() {
  export VAGRANT_DEFAULT_PROVIDER=virtualbox
  export VAGRANT_CONTEXT="${VAGRANT_DEFAULT_PROVIDER}/dev"
  
  export TEST_TYPES=dev:acceptance
  export HATS=dev
}