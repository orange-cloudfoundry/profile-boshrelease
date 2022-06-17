#!/bin/bash
# this file will always been sourced (first) in any profiles

# shellcheck disable=SC2164

# functions ##################################################################

######################################
# load an environment profile as root
# Globals:
#   PROFILE_BASE
# Arguments:
#   a profile name
######################################
load() {
	sudo -i PROFILE_BASE="$PROFILE_BASE" \
	bash --noprofile --rcfile "$(realpath -e "${PROFILE_BASE}/${1:?required}/profile.sh")"
}

######################################
# Returns:
#   true if $1 is in $2
######################################
isin() {
	# shellcheck disable=SC2295
	[ -n "$2" ] && [ -z "${2##*${1}*}" ]
}

######################################
# flatten JSON paths
######################################
jflat() {
	jq -cr 'paths(scalars) as $p|"."+($p|map(if type=="number" then "["+tostring+"]" else tostring end)|join(".")|split(".[")|join("["))+"="+(getpath($p)|@sh)'
}
######################################
# flatten YAML paths (alias yflatten)
######################################
yflat() {
	y2j | jflat
}

######################################
# JSON / YAML conversion
# Requires: python3-yaml / PyYAML
######################################
j2y() {
	python3 -c 'import sys,json,yaml;print(yaml.safe_dump(json.load(sys.stdin), default_flow_style=0, explicit_start=1, explicit_end=1), end="")'
}

y2j() {
	python3 -c 'import sys,json,yaml;print(json.dumps(yaml.safe_load(sys.stdin), indent=2, sort_keys=1))'
}

######################################
# yq without yq
######################################
command -v yq >/dev/null 2>&1 ||
yq() {
	if [ -t 0 ]
	then
		>&2 echo error: please provide input on stdin
		return 64
	fi
	y2j 2>/dev/null | jq "$@"
}

######################################
# chdir to the specified element
######################################
go-() {
	case "$1" in
	jobs)
		cd /var/vcap/jobs
		;;
	job)
		cd "/var/vcap/jobs/${2}"
		;;
	packages)
		cd /var/vcap/packages
		;;
	package)
		cd "/var/vcap/packages/${2}"
		;;
	logs)
		cd /var/vcap/sys/log
		;;
	log)
		cd "/var/vcap/sys/log/${2}"
		;;
	mysql)
		  mysql --defaults-file=/var/vcap/jobs/pxc-mysql/config/mylogin.cnf
	;;
	gorouter|router)
		</var/vcap/jobs/gorouter/config/gorouter.yml \
		yq -r '.status|"curl -u "+(.user|@sh)+":"+(.pass|@sh)+" http://localhost:"+(.port|@sh)+"'"${2:-/routes}"'"'
	;;
	help)
		cat <<-'EOF'
		jobs | job [name]          chdir into [given] job directory
		packages | package [name]  chdir into [given] package directory
		logs | log [name]          chdir into [given] log directory
		EOF
		[ -f "/var/vcap/jobs/pxc-mysql/config/mylogin.cnf" ] &&
		echo "mysql                      run mysql CLI with configuration"
		[ -f "/var/vcap/jobs/gorouter/config/gorouter.yml" ] &&
		echo "gorouter|router [path]     output curl to query gorouter [routing table]"
		;;
	*)
		>&2 echo error: try "help"
		return 64
	esac
}

######################################
# list available monit jobs
######################################
list-jobs() {
	find -L /var/vcap/jobs -maxdepth 1 -mindepth 1 -type d -exec basename {} \;
}


# functions: bash completion #################################################
__complete_load() {
	[ "$COMP_CWORD" = 1 ] || return
	readarray -t COMPREPLY < <(
		compgen -W "$(find "$PROFILE_BASE" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)" \
		-- "${COMP_WORDS[COMP_CWORD]}"
	)
}
complete -F __complete_load load

__complete_monit() {
	COMPREPLY=()
	case "${COMP_WORDS[COMP_CWORD-1]}" in
	start|stop|restart|monitor|unmonitor)
		readarray -t COMPREPLY < <(
			compgen -W "$(list-jobs) all" -- "${COMP_WORDS[COMP_CWORD]}"
		)
		return
		;;
	esac

	case "${COMP_WORDS[COMP_CWORD]}" in
	-*)
		readarray -t COMPREPLY < <(
			compgen -W "$(monit -h | awk '$1 ~ /^-/{print $1}')" \
			-- "${COMP_WORDS[COMP_CWORD]}"
		)
		return 0
		;;
	*)
		readarray -t COMPREPLY < <(
			compgen -W "$(monit -h | sed -n '/^Optional action/,/^$/{s/^ \([a-z]*\) .*/\1/p}' | uniq)" \
			-- "${COMP_WORDS[COMP_CWORD]}"
		)
	esac
}
complete -F __complete_monit monit

__complete_go-() {
	local keywords
	COMPREPLY=()
	case "${COMP_WORDS[COMP_CWORD-1]}" in
	job|log)
		readarray -t COMPREPLY < <(
			compgen -W "$(list-jobs)" -- "${COMP_WORDS[COMP_CWORD]}"
		)
		return
		;;
	package)
		readarray -t COMPREPLY < <(
			compgen	-W "$(find -L /var/vcap/packages -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)" \
			-- "${COMP_WORDS[COMP_CWORD]}"
		)
		;;
	router|gorouter)
		readarray -t COMPREPLY < <(compgen -W "/routes /" -- "${COMP_WORDS[COMP_CWORD]}")
		return
		;;
	esac

	if [ "$COMP_CWORD" != 1 ]
	then return
	fi

	[ -f "/var/vcap/jobs/pxc-mysql/config/mylogin.cnf" ] &&
	keywords="${keywords} mysql"
	[ -f "/var/vcap/jobs/gorouter/config/gorouter.yml" ] &&
	keywords="${keywords} router gorouter"

	readarray -t COMPREPLY < <(
		compgen -W "jobs job packages package logs log ${keywords}" -- "${COMP_WORDS[COMP_CWORD]}"
	)
}
complete -F __complete_go- go-


# variables ##################################################################

export PYTHONDONTWRITEBYTECODE=1
export PS1='\u@\h:\w\$ '

if [ -n "${BASH_SOURCE:-}" ] && [ -z "$PROFILE_BASE" ]
then
	PROFILE_BASE=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
	export PROFILE_BASE
fi
