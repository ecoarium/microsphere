#!/usr/bin/env bash

register_workspace_setting 'aws_play'

function set_workspace_settings_to_aws_play() {
  export VAGRANT_DEFAULT_PROVIDER=aws
  export VAGRANT_CONTEXT="${VAGRANT_DEFAULT_PROVIDER}/play"

  export TEST_TYPES=acceptance
  export HATS=aws_play
}
