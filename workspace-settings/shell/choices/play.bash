#!/usr/bin/env bash

register_workspace_setting 'play'

function set_workspace_settings_to_play() {
  export VAGRANT_DEFAULT_PROVIDER=virtualbox
  export VAGRANT_CONTEXT="${VAGRANT_DEFAULT_PROVIDER}/play"

  export TEST_TYPES=:
  export HATS=:
}
