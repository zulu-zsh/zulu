###
# Output usage information
###
function _zulu_uninstall_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu uninstall <packages...>"
}

###
# Install a package
###
function _zulu_uninstall_package() {
  local package root

  package="$1"

  # Double check that the package name has been passed
  if [[ -z $package ]]; then
    echo $(_zulu_color red "Please specify a package name")
    echo
    _zulu_uninstall_usage
    return 1
  fi

  # Check if the package is already uninstalled
  root="$base/packages/$package"

  # Remove the package source
  #
  # TODO: Obviously, this works, but would really like to find a pure-zsh
  #       way of doing this safely *just in case* the root variable doesn't
  #       get populated for some reason
  rm -rf "$root"

  return $?
}

###
# Zulu command to handle package installation
###
function _zulu_uninstall() {
  local base index packages out

  # Parse options
  zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_uninstall_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config_dir=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="${base}/index/packages"

  # If no context is passed, output the contents of the pathfile
  if [[ "$1" = "" ]]; then
    echo $(_zulu_color red "Please specify a package name")
    echo
    _zulu_uninstall_usage
    return 1
  fi

  # Do a first loop, to ensure all packages exist
  for package in "$@"; do
    if [[ ! -f "$index/$package" ]]; then
      echo $(_zulu_color red "Package '$package' is not in the index")
      return 1
    fi

    if [[ ! -d "$base/packages/$package" ]]; then
      echo $(_zulu_color red "Package '$package' is not installed")
      return 1
    fi
  done

  # Do a second loop, to do the actual install
  for package in "$@"; do
    zulu unlink $package
    [ $? -ne 0 ] && return 1

    _zulu_revolver start "Uninstalling $package..."
    out=$(_zulu_uninstall_package "$package" 2>&1)
    state=$?
    _zulu_revolver stop

    if [ $state -eq 0 ]; then
      echo "$(_zulu_color green '✔') Finished uninstalling $package"
    else
      echo "$(_zulu_color red '✘') Error uninstalling $package"
      echo "$out"
    fi
  done

  zulu bundle --dump --force
}
