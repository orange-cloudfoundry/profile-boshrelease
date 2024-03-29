.PHONY: all

wildcard_recursive = $(foreach d,$(wildcard $(1:=/*)),$(call wildcard_recursive,$d,$2) $(filter $(subst *,%,$2),$d))
y2j := python3 -c 'import sys,json,yaml;print(json.dumps(yaml.safe_load(sys.stdin), indent=2, sort_keys=1))'
j2y := python3 -c 'import sys,json,yaml;print(yaml.safe_dump(json.load(sys.stdin), default_flow_style=0, explicit_start=1, explicit_end=1), end="")'
deps := find packages -mindepth 1 -maxdepth 1 -type d -printf '%f\n'|sort

all: jobs/bash-profiles/spec packages/bash-profiles/spec README.md

jobs/bash-profiles/spec: $(wildcard packages/*)
	$(eval tempfile := $(shell mktemp))
	@${y2j} < "$@" | \
	deps="$(shell ${deps})" jq '.packages=(env.deps|split(" "))' | \
	${j2y} > "${tempfile}"
	@cat "${tempfile}" > "$@"
	@rm -fr "${tempfile}"

packages/bash-profiles/spec: $(wildcard packages/*) $(call wildcard_recursive,src/bash-profiles,*)
	$(eval tempfile := $(shell mktemp))
	@${y2j} < "$@" | \
	deps="$(shell ${deps})" \
	files="$(shell find src -path '*/bash-profiles/*' -type f -printf '%P\n'|sort)" \
	jq '.files=(env.files|split(" "))' | \
	${j2y} > "${tempfile}"
	@cat "${tempfile}" > "$@"
	@rm -fr "${tempfile}"

README.md: $(wildcard releases/profile/*yml)
	sed '/releases:/,/^```$$/{s/[0-9]*\.[0-9]*\.[0-9][0-9]*/$(shell ls releases/profile/*-*.yml|sed 's/.*-//;s/\.yml//'|sort -Vr|head -1)/g}' -i "$@"
