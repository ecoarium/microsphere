#!/usr/bin/env bash

register_workspace_setting 'faro'

function set_workspace_settings_to_faro() {
  export VAGRANT_DEFAULT_PROVIDER=virtualbox
  export VAGRANT_CONTEXT="${VAGRANT_DEFAULT_PROVIDER}/faro"

  export TEST_TYPES=dev:acceptance
  export HATS=dev
}
