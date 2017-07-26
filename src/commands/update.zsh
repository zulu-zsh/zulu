###
# Print usage information
###
function _zulu_update_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu update [options]"
  builtin echo
  builtin echo $(_zulu_color yellow "Options:")
  builtin echo "  -c, --check       Check if an update is available"
  builtin echo "  -h, --help        Output this help text and exit"
}

###
# Update the zulu package index
###
function _zulu_update_index() {
  local old="$(pwd)"

  builtin cd $index
  command git rebase -p --autostash FETCH_HEAD
  builtin cd $old
}

function _zulu_update_check_for_update() {
  local old="$(pwd)"

  builtin cd "$base/index"

  command git fetch origin &>/dev/null

  if command git rev-parse --abbrev-ref @'{u}' &>/dev/null; then
    count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"

    down="$count[(w)2]"

    if [[ $down -gt 0 ]]; then
      builtin echo "$(_zulu_color green "Zulu index updates available") Run zulu update to update the index"
      builtin cd $old
      return
    fi
  fi

  builtin echo "$(_zulu_color green "No update available")"
  builtin cd $old
  return 1
}

###
# Update the zulu package index
###
function _zulu_update() {
  local help base index check

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  index="${base}/index"

  # Parse options
  builtin zparseopts -D h=help -help=help c=check -check=check

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_update_usage
    return
  fi

  if [[ -n $check ]]; then
    _zulu_revolver start "Checking for updates..."
    _zulu_update_check_for_update
    _zulu_revolver stop
    return
  fi

  _zulu_revolver start "Checking for updates..."
  if _zulu_update_check_for_update > /dev/null; then
    _zulu_revolver update "Updating package index..."
    out=$(_zulu_update_index 2>&1)
    _zulu_revolver stop

    if [ $? -eq 0 ]; then
      builtin echo "$(_zulu_color green '✔') Package index updated"
    else
      builtin echo "$(_zulu_color red '✘') Error updating package index"
      builtin echo "$out"
    fi

    return
  fi

  _zulu_revolver stop
  builtin echo "$(_zulu_color green "No update available")"
}
