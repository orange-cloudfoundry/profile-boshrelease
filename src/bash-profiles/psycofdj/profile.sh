#!/bin/bash

[ -n "${PROFILE_BASE}" ] &&
. "${PROFILE_BASE}/profile.sh"

export PROMPTCMD_COMMANDS=""
export PROMPT_COMMAND="RET=\$? promptcmd_run"
export PATH=/var/vcap/bosh/bin:$PATH
export TERM=xterm-256color

alias rm='rm -i'
alias l='ls -c -h -l --color=auto'
alias ll='l -a'
alias p='pwd'
alias h='cd ~'
alias k='cd ..'
alias c='clear'
alias ps='ps auxw  --sort=uid,pid,cmd'
alias sudo='sudo '
alias ios="iostat -xm 1"
alias s="monit summary"

function promptcmd_add_labels() {
  local c_var
  for c_var in $@; do
    strlist_add PROMPTCMD_LABELS "${c_var}"
  done
}

function promptcmd_enable() {
  local l_dir
  l_dir=$(dirname "$(realpath -e "${BASH_SOURCE[0]}")")
  export PS1=""
  export COLUMNS
  export PROMPTCMD_LABELS
  promptcmd_push "LC_ALL=C ${l_dir}/genprompt.sh"
}

function promptcmd_push() {
  local p_cmd=$1; shift
  if [ -z "${PROMPTCMD_COMMANDS}" ]; then
      PROMPTCMD_COMMANDS="${p_cmd}"
  else
    PROMPTCMD_COMMANDS="${PROMPTCMD_COMMANDS}; ${p_cmd}"
  fi
}

function promptcmd_run() {
  PROMPTCMD_LABELS=""
  export PS1=""
  eval "${PROMPTCMD_COMMANDS}"
}

function __prompt_export() {
  export ZONE=$(cat /var/vcap/instance/az)
  export ID=$(cat /var/vcap/instance/id)
  export DEPLOY=$(cat /var/vcap/instance/deployment)
  export NAME=$(cat /var/vcap/instance/name)
  export STATUS="faulty"
  if [ "${USER}" = "root" ]; then
    MONIT_STATUS=$(monit status 2>&1 | grep status)
    if [ -n "$MONIT_STATUS" ]
    then
      echo "$MONIT_STATUS" |
      grep -v  monitoring | grep -v accessible | grep -q -v running ||
      export STATUS="running"
    fi
  else
    export STATUS="???"
  fi
}

function list-packages() {
  find -L /var/vcap/packages/ -maxdepth 1 -mindepth 1 -type d | xargs -n1 basename
}

function go-job() {
  if [ ! -d /var/vcap/jobs/$1 ]; then
      echo "job '$1' not found" >&2
      return 1
  fi
  cd /var/vcap/jobs/$1
}

function go-package() {
  if [ ! -d /var/vcap/packages/$1 ]; then
      echo "pacakge '$1' not found" >&2
      return 1
  fi
  cd /var/vcap/packages/$1
}

function go-logs() {
  if [ ! -d /var/vcap/sys/log/$1 ]; then
      echo "log for job '$1' not found" >&2
      return 1
  fi
  cd /var/vcap/sys/log/$1
}

function logf() {
  if [ ! -d /var/vcap/sys/log/$1 ]; then
      echo "log for job '$1' not found" >&2
      return 1
  fi

  if [ "$2" == "all" ]; then
      tail -f /var/vcap/sys/log/$1/*.log
  else
    if [ -f /var/vcap/sys/log/$1/$1.stdout.log ]; then
        tail -f /var/vcap/sys/log/$1/$1.stdout.log
    elif [ -f /var/vcap/sys/log/$1/$1.log ]; then
        tail -f /var/vcap/sys/log/$1/$1.log
    else
      tail -f /var/vcap/sys/log/$1/*.log
    fi
  fi
}

function go-mysql() {
  mysql --defaults-file=/var/vcap/jobs/pxc-mysql/config/mylogin.cnf
}

function go-gorouter() {
  local l_config
  local l_user
  local l_password
  local l_port
  local l_path=$1

  l_config=$(grep -A3 -e '^status:' /var/vcap/jobs/gorouter/config/gorouter.yml)
  l_user=$(echo $(echo "${l_config}" | grep user | cut -d: -f2))
  l_password=$(echo $(echo "${l_config}" | grep pass | cut -d: -f2))
  l_port=$(echo $(echo "${l_config}" | grep port | cut -d: -f2))
  if [ -z "${l_path}" ]; then
      l_path="/routes"
      echo curl -u "${l_user}:${l_password}" http://localhost:${l_port}${l_path}
  else
    curl -u "${l_user}:${l_password}" http://localhost:${l_port}${l_path}
  fi
}

function go-help() {
  cat - <<EOS
  list-jobs:            list available monit jobs
  list-packages:        list available bosh packages
  go-job <name>:        cd into given job directory
  go-package <name>:    cd into given package directory
  go-logs <name>:       cf into logs directory
  logf <name> [all]:    tail -f logs of given job. 'all' logs or stdout
  go-mysql:             run mysql CLI with bosh login configuration (database instances)
  go-gorouter:          dump gorouter routing table (router instances)
EOS
}


promptcmd_push "__prompt_export"
promptcmd_enable


__complete_jobs() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY+=($(compgen -W "$(list-jobs)" -- "${cur}"))
}
complete -F __complete_jobs go-job go-logs logf

__complete_packages() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY+=($(compgen -W "$(list-packages)" -- $cur))
}
complete -F __complete_packages go-package
