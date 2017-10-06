#!/usr/bin/env bash

register_workspace_setting 'packer'

function change_packer_settings() {
  export PATHS_PROJECT_DEPLOY_PACKER_HOME="${PATHS_PROJECT_DEPLOY_HOME}/packer"

  local packer_baseline_dirs=()
  local packer_baseline_dir=''
  for packer_template_file in `find ${PATHS_PROJECT_DEPLOY_PACKER_HOME} -path "*/*" -type f -name 'template.json' -not -path "*/.build/*" -exec dirname '{}' \;`; do
    packer_baseline_dirs+=("${packer_template_file/${PATHS_PROJECT_DEPLOY_PACKER_HOME}\//}")
  done

  while true; do
    printf "\n"
    printf "\n"
    echo "  Choose a packer baseline:"

    local count=0
    local packer_choice=''
    for packer_baseline_dir in "${packer_baseline_dirs[@]}"
    do
      packer_choice="${packer_baseline_dir//\// }"
      let "count++"
      echo "     $count. $packer_choice"
    done

    local answer=''
    read -p "    choose (1-$count): " answer

    local original_answer=$answer
    let "answer--"
    if [[ -n "${packer_baseline_dirs[$answer]}" ]] ; then
      export PATHS_PROJECT_DEPLOY_PACKER_CONTEXT_PATH="${PATHS_PROJECT_DEPLOY_PACKER_HOME}/${packer_baseline_dirs[$answer]}"
      export PACKER_CONTEXT="${packer_baseline_dirs[$answer]}"
      break
    else
      echo "Invalid option: $original_answer"
    fi

  done

  show_packer_settings
}

function show_packer_settings() {

  local packer_nice_name="$(echo "${PATHS_PROJECT_DEPLOY_PACKER_CONTEXT_PATH}" | awk -F '/' '{print $(NF-1) " " $NF}')"
  good "

######################################    PACKER OS CHOICE $(echo "${packer_nice_name}" | awk '{print toupper($0)}')    #####################################

            PATHS_PROJECT_DEPLOY_PACKER_HOME:          ${PATHS_PROJECT_DEPLOY_PACKER_HOME}
            PATHS_PROJECT_DEPLOY_PACKER_CONTEXT_PATH:  ${PATHS_PROJECT_DEPLOY_PACKER_CONTEXT_PATH}
            PACKER_CONTEXT:             ${PACKER_CONTEXT}

              if you wish to change these settings execute the following in your terminal:

                                    change_packer_settings


#####################################################################################################

"
}

function set_workspace_settings_to_packer() {

  change_packer_settings

  export VAGRANT_DEFAULT_PROVIDER=virtualbox
  export VAGRANT_CONTEXT="${VAGRANT_DEFAULT_PROVIDER}/packer/${PACKER_CONTEXT}"

  export TEST_TYPES=packer
  export HATS=packer
}
