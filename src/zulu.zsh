###
# Print usage information
###
function _zulu_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu [options] <command>"
  builtin echo
  builtin echo $(_zulu_color yellow "Options:")
  builtin echo "  -h, --help          Output this help text and exit"
  builtin echo "  -v, --version       Output version information and exit"
  builtin echo
  builtin echo $(_zulu_color yellow "Commands:")
  builtin echo "  alias <args>          Functions for adding/removing aliases"
  builtin echo "  bundle                Install all packages from packagefile"
  builtin echo "  cdpath <args>         Functions for adding/removing dirs from \$cdpath"
  builtin echo "  fpath <args>          Functions for adding/removing dirs from \$fpath"
  builtin echo "  func <args>           Functions for adding/removing functions"
  builtin echo "  info                  Show information for a package"
  builtin echo "  install <package>     Install a package"
  builtin echo "  link <package>        Create symlinks for a package"
  builtin echo "  list                  List packages"
  builtin echo "  manpath               Functions for adding/removing dirs from \$manpath"
  builtin echo "  path <args>           Functions for adding/removing dirs from \$path"
  builtin echo "  theme <theme>         Select a prompt theme"
  builtin echo "  search                Search the package index"
  builtin echo "  self-update           Update zulu"
  builtin echo "  switch                Switch to a different version of a package"
  builtin echo "  sync                  Sync your Zulu environment to a remote repository"
  builtin echo "  uninstall <package>   Uninstall a package"
  builtin echo "  unlink <package>      Remove symlinks for a package"
  builtin echo "  update                Update the package index"
  builtin echo "  upgrade <package>     Upgrade a package"
  builtin echo "  var <args>            Functions for adding/removing environment variables"
}

function _zulu_version() {
  command cat "$base/core/.version"
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
  builtin zparseopts -D h=help -help=help v=version -version=version

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
    builtin echo " _____         ___"
    builtin echo "/__  /  __  __/  /_  __"
    builtin echo "  / /  / / / /  / / / /"
    builtin echo " / /__/ /_/ /  / /_/ /"
    builtin echo "/____/\\____/__/\\____/"
    builtin echo
    builtin echo "Version $(zulu --version)"
    builtin echo
    _zulu_usage
    return
  fi

  # If we're in dev mode, re-source the command now
  if (( $+functions[_zulu_${cmd}] )) && [[ $ZULU_DEV_MODE -eq 1 ]]; then
    builtin source "$base/core/src/commands/$cmd.zsh"
  fi

  # Check if the requested command exists
  if (( ! $+functions[_zulu_${cmd}] )); then
    # If it doesn't, print usage information and exit
    builtin echo $(_zulu_color red "Command '$cmd' can not be found.")
    builtin echo
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
