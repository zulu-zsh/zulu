###
# Print usage information
###
function _zulu_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu [options] <command>"
  echo
  echo $(_zulu_color yellow "Options:")
  echo "  -h, --help          Output this help text and exit"
  echo "  -v, --version       Output version information and exit"
  echo
  echo $(_zulu_color yellow "Commands:")
  echo "  alias <args>          Functions for adding/removing aliases"
  echo "  bundle                Install all packages from packagefile"
  echo "  cdpath <args>         Functions for adding/removing dirs from \$cdpath"
  echo "  fpath <args>          Functions for adding/removing dirs from \$fpath"
  echo "  func <args>           Functions for adding/removing functions"
  echo "  info                  Show information for a package"
  echo "  install <package>     Install a package"
  echo "  link <package>        Create symlinks for a package"
  echo "  list                  List packages"
  echo "  manpath               Functions for adding/removing dirs from \$manpath"
  echo "  path <args>           Functions for adding/removing dirs from \$path"
  echo "  theme <theme>         Select a prompt theme"
  echo "  search                Search the package index"
  echo "  self-update           Update zulu"
  echo "  switch                Switch to a different version of a package"
  echo "  sync                  Sync your Zulu environment to a remote repository"
  echo "  uninstall <package>   Uninstall a package"
  echo "  unlink <package>      Remove symlinks for a package"
  echo "  update                Update the package index"
  echo "  upgrade <package>     Upgrade a package"
  echo "  var <args>            Functions for adding/removing environment variables"
}

function _zulu_version() {
  cat "$base/core/.version"
}

###
# The main zulu command. Loads and executes all other commands
###
function zulu() {
  local cmd base help version

  autoload -Uz is-at-least

  # Set up some source paths
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}

  # Parse CLI options
  zparseopts -D h=help -help=help v=version -version=version

  # Print help
  if [[ -n $help ]]; then
    _zulu_usage
    return
  fi

  if [[ -n $version ]]; then
    _zulu_version
    return
  fi

  cmd="$1"

  if [[ -z $cmd ]]; then
    echo " _____         ___"
    echo "/__  /  __  __/  /_  __"
    echo "  / /  / / / /  / / / /"
    echo " / /__/ /_/ /  / /_/ /"
    echo "/____/\\____/__/\\____/"
    echo
    echo "Version $(zulu --version)"
    echo
    _zulu_usage
    return
  fi

  # If we're in dev mode, re-source the command now
  if (( $+functions[_zulu_${cmd}] )) && [[ $ZULU_DEV_MODE -eq 1 ]]; then
    source "$base/core/src/commands/$cmd.zsh"
  fi

  # Check if the requested command exists
  if (( ! $+functions[_zulu_${cmd}] )); then
    # If it doesn't, print usage information and exit
    echo $(_zulu_color red "Command '$cmd' can not be found.")
    echo
    _zulu_usage
    return 1
  fi


  # If the user initiated this call, then track it
  if [[ $ZULU_DEV_MODE -ne 1 && "${${(s/:/)funcfiletrace[1]}[1]}" != "$base/core/zulu" ]]; then
    {
      _zulu_analytics_track "Ran command: $cmd $2"
    } &!
  fi

  # Execute the requested command
  _zulu_${cmd} "${(@)@:2}"
}
