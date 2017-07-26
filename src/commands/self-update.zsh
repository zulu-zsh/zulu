###
# Print usage information
###
function _zulu_self-update_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu self-update [options]"
  builtin echo
  builtin echo $(_zulu_color yellow "Options:")
  builtin echo "  -c, --check       Check if an update is available"
  builtin echo "  -h, --help        Output this help text and exit"
}

###
# Update the zulu core
###
function _zulu_self-update_core() {
  local old="$(pwd)"

  builtin cd $core
  command git rebase -p --autostash FETCH_HEAD

  if [[ $? -eq 0 ]]; then
    builtin echo "$(_zulu_color red '✗') Zulu core failed to update"
  fi

  [[ -f build.zsh ]] && ./build.zsh
  builtin source zulu
  _zulu_init
  builtin cd $old
}

function _zulu_self-update_check_for_update() {
  local old="$(pwd)"

  builtin cd "$base/core"

  command git fetch origin &>/dev/null

  if command git rev-parse --abbrev-ref @'{u}' &>/dev/null; then
    count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"

    down="$count[(w)2]"

    if [[ $down -gt 0 ]]; then
      builtin echo "$(_zulu_color green "New Zulu version available") Run zulu self-update to upgrade"
      builtin cd $old
      return
    fi
  fi

  builtin echo $(_zulu_color green 'No update available')
  builtin cd $old
  return 1
}

###
# Update the zulu core
###
function _zulu_self-update() {
  local help base core check

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  core="${base}/core"

  # Parse options
  builtin zparseopts -D h=help -help=help c=check -check=check

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_self-update_usage
    return
  fi

  if [[ -n $check ]]; then
    _zulu_revolver start "Checking for updates..."
    _zulu_self-update_check_for_update
    _zulu_revolver stop
    return
  fi

  _zulu_revolver start "Checking for updates..."
  if _zulu_self-update_check_for_update > /dev/null; then
    _zulu_revolver update "Updating zulu core..."
    out=$(_zulu_self-update_core 2>&1)
    _zulu_revolver stop

    if [ $? -eq 0 ]; then
      builtin echo "$(_zulu_color green '✔') Zulu core updated"
    else
      builtin echo "$(_zulu_color red '✘') Error updating zulu core"
      builtin echo "$out"

      return 1
    fi

    return
  fi

  _zulu_revolver stop
  builtin echo "$(_zulu_color green "No update available")"
}
