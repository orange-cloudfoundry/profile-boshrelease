#!/bin/bash

packages=("jq" "yq" "fpinq" "bat" "ripgrep")
for package in "${packages[@]}"; do
  package_dir="/var/vcap/packages/${package}"
  if [[ -d "${package_dir}" ]]; then
    # find bin or sbin
    for bin_dir in $(find "${package_dir}" -type d -regextype sed -regex ".*/s\?bin"); do
      export PATH="bin_dir}:${PATH}"
    done
  fi
done