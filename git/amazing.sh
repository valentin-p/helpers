git log --graph --oneline --decorate $( git fsck --no-reflog | awk '/dangling commit/ {print $3}' ) # Amazing graph to recover lost commit or stash


# Tools: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
