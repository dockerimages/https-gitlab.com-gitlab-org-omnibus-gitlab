#!/bin/bash
function jh_env_var()
{
  [[ "${jh}" == "true" ]]
}

function jh_branch_var(){
  [[ -n "${GITLAB_VERSION}" ]] && [[ "${GITLAB_VERSION}" == *-jh ]]
}

function jh_branch_name(){
  grep -q -E "\-jh" VERSION
}

jh_env_var || jh_branch_var || jh_branch_name