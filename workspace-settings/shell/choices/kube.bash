#!/usr/bin/env bash

register_workspace_setting 'kube'

function set_workspace_settings_to_kube() {
  export VAGRANT_DEFAULT_PROVIDER=virtualbox
  export VAGRANT_CONTEXT="${VAGRANT_DEFAULT_PROVIDER}/kube"

  export TEST_TYPES=:
  export HATS=kube
}
