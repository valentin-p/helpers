#!/usr/bin/env bash
set -euo pipefail
inputs=("$@")

BRANCH=$(git rev-parse --abbrev-ref HEAD  | cut -d/ -f1)
inputs+=("$BRANCH")
EXCLUDE=$(echo "${inputs[@]}" | tr ' ' '|' | sed 's/|/\\|/g') # 861\|FEUR-812\|669
git branch --format "%(upstream)|%(refname:short)|%(authoremail)" | awk -F'|' '{if ($1 != "") printf "%-36s %s\n", $3, $2;}' | grep -vE "develop|main" | grep -v "$EXCLUDE"
prompt_for_approve() {
    while true; do
      read -rp "Delete ALL local branches? (DEFAULT: y/[N]o):" continue_yn
      case $continue_yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) exit;;
      esac
  done
}
prompt_for_approve
git branch --format "%(upstream)|%(refname:short)|%(authoremail)" | awk -F'|' '{if ($1 != "") printf "%-36s %s\n", $3, $2;}' | grep -vE "develop|main" | grep -v "$EXCLUDE" | awk '{print $2;}' | xargs git branch -D
git fetch -p ; git branch -r | awk '{print $1}' | grep -E -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d
