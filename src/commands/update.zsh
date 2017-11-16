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
  local stub="packages/"
  typeset -A files
  typeset -a changed; changed=()
  typeset -a new; new=()
  typeset -a removed; removed=()

  builtin cd $index

  # Get the list of changed files
  files=($(command git diff --name-status HEAD...@'{u}' 2>&1))

  # Sort files into arrays for changed, new and removed packages
  for type file in "${(@kv)files}"; do
    if [[ $type == 'M' ]]; then
      changed=($changed ${file//${stub}/})
    fi

    if [[ $type == 'A' ]]; then
      new=($new ${file//${stub}/})
    fi

    if [[ $type == 'D' ]]; then
      removed=($removed ${file//${stub}/})
    fi
  done

  # Update the index
  local out=$(command git rebase -p --autostash FETCH_HEAD >/dev/null 2>&1)
  if [ $? -ne 0 ]; then
    builtin echo $(color red $out)
    return 1
  fi

  # Print the updated packages
  if [ ${#changed} -gt 0 ]; then
    builtin echo $(color yellow 'Updated packages')
    builtin echo "  $changed"
  fi

  if [ ${#new} -gt 0 ]; then
    builtin echo $(color yellow 'New packages')
    builtin echo "  $new"
  fi

  if [ ${#removed} -gt 0 ]; then
    builtin echo $(color yellow 'Deleted packages')
    builtin echo "  $removed"
  fi

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
      builtin echo "$out"
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
