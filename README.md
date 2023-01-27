# BOSH Linux bash-profiles release

This BOSH release provides additional binaries and BASH profiles for day-to-day operations.

## Binaries

- [`as-tree`](https://github.com/jez/as-tree), from Jake Zimmerman
- [`bat`](https://github.com/sharkdp/bat), from David Peter
- [`fping`](https://fping.org/)
- [`jq`](https://github.com/stedolan/jq/), from Stephen Dolan, to manipulate JSON files
- [`rg`](https://github.com/BurntSushi/ripgrep), from Andrew Gallant

## BASH profiles

- custom shell aliases (type `alias` to see what is available)
- custom shell functions to ease the operational tasks (with shell-completion!)
- shell completion for [`monit`](https://mmonit.com/monit/)
- different shell profiles through `load $profile_name`

### psycofdj profile

- shell functions (try: `go-help` to get a list!)
- a prompt with useful information
  - current deployment
      - 🟥 (red) for cf
      - 🟦 (cyan) for prometheus
      - 🟨 (yellow) default
  - current monit status (root user only)
      - 🟩 (green) all running
      - 🟥 (red) at least 1 faulty job
  - current user
      - 🟪 (magenta) for root
      - 🟨 (yellow) default
  - instance name and zone
      - 🟪 (magenta) for *important* products like a database, consul or singleton-blobstore
      - 🟥 (red) for *control-plane* products like router, tcp-router and diego-cell
      - 🟨 (yellow) default
  - last shell status
      - 🟩 (green) for 0 / EX_OK
      - 🟥 (red+blink) defaults
  - 🟥 (red) last prompt datetime
  - 🟦 (cyan) current cwd

### toor profile

A more minimalistic profile, also serving as an example.

## Usage

Include the job in all `instance_groups` running the Ubuntu stemcell; example:

```yaml
addons:
  - name: profile
    include:
      stemcell:
        - os: ubuntu-bionic
    jobs:
      - name: bash-profiles
        properties: {}
        release: profile

releases:
  - name: profile
    version: "0.1.5"
    url: https://github.com/orange-cloudfoundry/profile-boshrelease/releases/download/v0.1.5/profile-0.1.5.tgz
    sha1: ...
```
