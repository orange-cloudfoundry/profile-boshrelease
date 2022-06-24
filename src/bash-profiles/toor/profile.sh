#!/bin/bash

[ -n "${PROFILE_BASE}" ] &&
. "${PROFILE_BASE}/profile.sh"

# functions ##################################################################

# aliases ####################################################################

alias dmesg='dmesg -HPT'
alias l='ls -AF --color=auto'
alias ls='ls -AF --color=auto'
alias ll='ls -lAvh --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# variables ##################################################################

export LESS='-c -i -M -R'
export LESSHISTFILE='-'

export VISUAL='vim' EDITOR='vim'

export HISTCONTROL='ignoredups:erasedups'
export HISTSIZE=1000
export HISTFILESIZE=
export HISTTIMEFORMAT='%FT%T '

export PROMPT_COMMAND="history -a"

######################################
# instance related variables
######################################
export instance_az=$(cat /var/vcap/instance/az)
export instance_deployment=$(cat /var/vcap/instance/deployment)
export instance_id=$(cat /var/vcap/instance/id)
export instance_name=$(cat /var/vcap/instance/name)

export PS1="\[\033[40;33m\]\u\[\033[37m\]@\[\033[31m\]${instance_name}\[\033[37m\]-\[\033[34m\]${instance_az}\[\033[37m\]:\[\033[36m\]\w\[\033[37m\]\$\[\033[m\] "
