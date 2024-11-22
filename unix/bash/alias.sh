#!/bin/bash
set +e

# Function to add a line to a file if it doesn't already exist
add_line_if_not_exists() {
  local alias="$1"
  local file="$2"
  local alias_name="${alias%%=*}"

  if grep -Fxq "$alias" "$file"; then
    return
  else
    if grep -Fq "$alias_name" "$file"; then
      echo "The $alias is wrong in $file"
    else
      echo "$alias" | sudo tee -a "$file" >/dev/null
    fi
  fi
}

# Add aliases to ~/.zshrc
add_line_if_not_exists 'alias build=".bin/build.sh"' ~/.zshrc
add_line_if_not_exists 'alias run=".bin/run.sh"' ~/.zshrc
add_line_if_not_exists 'alias rst=".bin/restart.sh"' ~/.zshrc
add_line_if_not_exists 'alias lgd=".bin/composer-log.sh"' ~/.zshrc
add_line_if_not_exists 'alias ncf="cd src/broker-console || true && npm run cf"' ~/.zshrc
add_line_if_not_exists 'alias gitPruneAll=".bin/helper/git/git-prune-all.sh"' ~/.zshrc
add_line_if_not_exists 'alias gr1="git reset HEAD~1"' ~/.zshrc
add_line_if_not_exists 'alias gggrbm="gf && ggl && gco main && ggl && gco - && grb main"' ~/.zshrc
