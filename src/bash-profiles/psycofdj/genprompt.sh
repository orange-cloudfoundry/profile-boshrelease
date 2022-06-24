#!/bin/bash

declare -A RUNES=(
  [header]="⇶"
  [separator]="─"
)

declare -A COLORS=(
  [black]="30"
  [red]="31"
  [green]="32"
  [yellow]="33"
  [blue]="34"
  [magenta]="35"
  [cyan]="36"
  [white]="37"
  [lightblack]="90"
  [lightred]="91"
  [lightgreen]="92"
  [lightyellow]="93"
  [lightblue]="94"
  [lightmagenta]="95"
  [lightcyan]="96"
  [lightwhite]="97"
)

declare -A CONFIG=(
  [separator]="lightgreen"
  [header]="lightgreen"
  [hostname]="lightyellow"
  [pwd]="lightcyan"
  [pwd_collapsed]="cyan"
  [date]="lightred"
)

declare -A CONFIG_RET=(
  [ok]="lightgreen"
  [ko]="lightred"
)

declare -A CONFIG_USERNAME=(
  [root]="lightmagenta"
  [nonroot]="lightyellow"
)

declare -A CONFIG_NAME=(
  [default]="lightyellow"
  [diego-cell]="lightred"
  [router]="lightred"
  [diego-cell-pub]="lightred"
  [router-pub]="lightred"
  [database]="lightmagenta"
)

declare -A CONFIG_STATUS=(
  [running]="green"
  [faulty]="lightred"
  [default]="lightmagenta"
)

declare -A CONFIG_DEPLOY=(
  [default]="lightyellow"
  [cf]="lightred"
  [prometheus]="lightcyan"
)

function split {
  local l_ifs=$1; shift
  local l_oldIFS=${IFS}

  IFS=${l_ifs}
  for i in "$@"; do
    if [ -n "$i" ]; then
      echo $i
    fi
  done
  IFS=${l_oldIFS}
}

function echo_color {
  local l_text=$1; shift
  local l_color=$1; shift
  local l_len=${#l_text}

  if [ -z "${l_color}" ]; then
    l_color="lightmagenta"
  fi
  local l_code=${COLORS[${l_color}]}
  echo -n -e "\e[${l_code}m${l_text}\e[0m"
  count=$((count + l_len))
}


function echo_color_blink {
  local l_text=$1; shift
  local l_color=$1; shift
  local l_len=${#l_text}

  if [ -z "${l_color}" ]; then
    l_color="lightmagenta"
  fi
  local l_code=${COLORS[${l_color}]}
  echo -n -e "\e[${l_code};5m${l_text}\e[0m"
  count=$((count + l_len))

}

function compute_labels {
  local l_count=0
  if [ -n "${PROMPTCMD_LABELS}" ]; then
    for c_label in $(split ";" ${PROMPTCMD_LABELS}); do
      l_text=$(echo ${c_label} | cut -d'|' -f1)
      l_color=$(echo ${c_label} | cut -d'|' -f2)
      labels+=($(echo_color ${l_text} ${l_color}))
      l_len=${#l_text}
      l_count=$((l_count + l_len))
    done
  fi
  count=${l_count}
}

function write_header {
  local l_color=${CONFIG[header]}
  count=$((count-4))
  echo_color "\n${RUNES[header]} " ${l_color}
}

function write_deploy {
  local l_color=${CONFIG_DEPLOY[${DEPLOY}]}
  if [ -z "${l_color}" ]; then
    l_color=${CONFIG_DEPLOY[default]}
  fi

  echo_color "[" ${CONFIG[separator]}
  echo_color "${DEPLOY}" ${l_color}
  echo_color "]" ${CONFIG[separator]}
}

function write_sep {
  count=$((count-2))
  echo_color " ${RUNES[separator]} " ${CONFIG[separator]}
}

function write_status {
  local l_color=${CONFIG_STATUS[${STATUS}]}
  if [ -z "${l_color}" ]; then
    l_color=${CONFIG_STATUS[default]}
  fi

  echo_color "[" ${CONFIG[separator]}
  echo_color "${STATUS}" ${l_color}
  echo_color "]" ${CONFIG[separator]}
}


function write_host {
  local l_user=""
  if [ "${USER}" == "root" ]; then
    l_user=${CONFIG_USERNAME[root]}
  else
    l_user=${CONFIG_USERNAME[nonroot]}
  fi

  local l_name=${CONFIG_NAME[${NAME}]}
  if [ -z "${l_name}" ]; then
    l_name=${CONFIG_NAME[default]}
  fi

  echo_color "${USER}" ${l_user}
  echo_color "@" ${CONFIG[separator]}
  echo_color "${NAME}" ${l_name}
  echo_color ":" ${CONFIG[separator]}
  echo_color "${ZONE}" ${l_name}
}

function write_ret {
  if [ "${RET}" == "0" ]; then
    echo_color ${RET} ${CONFIG_RET[ok]}
  else
    echo_color_blink ${RET} ${CONFIG_RET[ko]}
  fi
}

function write_date {
  local l_value=$(date +%H:%M:%S)
  echo_color ${l_value} ${CONFIG[date]}
}


function write_labels {
  local l_count=${#labels[@]}
  for c_idx in $(seq 0 $((l_count - 1))); do
    local l_text=${labels[${c_idx}]}
    echo -e -n ${l_text}
    if [ ${c_idx} -ne $((l_count - 1)) ]; then
      echo_color "|" ${CONFIG[separator]}
    fi
  done
}


function write_pwd {
  local l_cols=${COLUMNS}
  local l_left=$((l_cols - count))
  local l_color=${CONFIG[pwd]}
  local l_pwd=$(pwd)
  local l_pwdLen=${#l_pwd}

  if [ ${l_pwdLen} -gt ${l_left} ]; then
    l_max=$((l_left - 5))
    l_pwd="${l_pwd:0:${l_max}}..."
  fi
  echo_color ${l_pwd} ${l_color}
  echo_color " " ${l_color}
}

function write_line {
  for c_idx in $(seq ${count} $((COLUMNS -1))); do
    echo_color "${RUNES[separator]}" ${CONFIG[separator]}
  done
  echo ""
  echo ""
}


declare -a labels=()
count=0
TERM=xterm-256color

compute_labels
write_header
write_deploy
write_sep
write_status
write_sep
write_host
write_sep
write_ret
write_sep
write_date
write_sep
write_labels
write_sep
write_pwd
write_line
