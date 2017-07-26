###
# Output usage information
###
function _zulu_switch_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu switch <options> <package>"
  builtin echo
  builtin echo $(_zulu_color yellow "Options:")
  builtin echo "  -b, --branch <branch>   Checkout the specified branch"
  builtin echo "  -t, --tag <tag>         Checkout the specified tag or commit"
}

###
# Checkout the provided tag or branch in the package repository
###
function _zulu_switch_checkout() {
  local package="$1" ref="$2"
  local base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}

  if ! _zulu_info_is_installed $package; then
    builtin echo $(_zulu_color red "Package $package is not installed")
  fi

  local oldPWD=$PWD
  builtin cd "$base/packages/$package"

  command git fetch origin >/dev/null 2>&1
  output=$(command git checkout -qf $ref 2>&1)
  state=$?

  builtin cd $oldPWD
  builtin unset oldPWD

  if [[ $state -ne 0 ]]; then
    builtin echo $(_zulu_color red "Failed to checkout $ref of package $package")
    builtin echo $output

    return 1
  fi

  builtin echo "$(_zulu_color green '✔') Successfully switched $package to $ref"
}

###
# Zulu command to handle path manipulation
###
function _zulu_switch() {
  local ctx base help branch tag ref

  # Parse options
  builtin zparseopts -D h=help -help=help \
    b:=branch -branch:=branch \
    t:=tag -tag:=tag

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_switch_usage
    return
  fi

  if [[ -z $branch && -z $tag ]]; then
    builtin echo $(_zulu_color red 'You must specify a branch or tag')
    return 1
  fi

  if [[ -n $branch && -n $tag ]]; then
    builtin echo $(_zulu_color red 'You must only specify one of branch or tag')
    return 1
  fi

  if [[ -n $branch ]]; then
    builtin shift branch
    ref=$branch
  fi

  if [[ -n $tag ]]; then
    builtin shift tag
    ref=$tag
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  package="$1"

  # Call the relevant function
  _zulu_switch_checkout $package $ref
}
