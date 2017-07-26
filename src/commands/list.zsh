###
# Print usage information
###
function _zulu_list_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu list [options]"
  builtin echo
  builtin echo $(_zulu_color yellow "Options:")
  builtin echo "  -a, --all            List all packages in the index"
  builtin echo "  -d, --describe       Include package description in output"
  builtin echo "  -h, --help           Output this help text and exit"
  builtin echo "  -i, --installed      List only installed packages (default)"
  builtin echo "  -n, --not-installed  List non-installed packages"
  builtin echo "  -s, --simple         Hide the 'package installed' indicator"
  builtin echo "  -t, --type <type>    Limit results to packages of <type>"
  builtin echo "      --branch         Print the current branch (if one is checked out)"
  builtin echo "      --tag            Print the current tag (if one is checked out)"
}

###
# Output a list of packages
###
function _zulu_list_packages() {
  local base index files json packages package type name description pad lim

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="$base/index/packages"

  for package in $(command ls $index); do
    # If --installed is passed but the package is not installed,
    # then skip past it
    if [[ -n $installed ]] && ! _zulu_info_is_installed $package; then
      continue
    fi

    # If --not-installed is passed but the package is installed,
    # then skip past it
    if [[ -n $not_installed ]] && _zulu_info_is_installed $package; then
      continue
    fi

    # We only need to read the package's index file if
    # the --type or --describe options are passed
    if [[ -n $package_type || -n $describe ]]; then
      json="$(command cat $index/$package)"
    fi

    # If --type is passed but the package is not of the
    # requested type, then skip past it
    if [[ -n $package_type ]]; then
      type=$(jsonval $json 'type')

      if [[ $type != $package_type ]]; then
        continue
      fi
    fi

    # Prevent ZVM from changing the ZSH version
    local old_ZVM_AUTO_USE=$ZVM_AUTO_USE
    builtin unset ZVM_AUTO_USE

    local suffix=''

    # If --branch is specified, get the current checked-out branch
    # for the package and print it alongside the name
    if [[ -n $branch ]] && _zulu_info_is_installed $package; then
      local oldPWD=$PWD
      builtin cd "$base/packages/$package"

      local current=$(command git status --short --branch -uno --ignore-submodules=all | command head -1 | command awk '{print $2}' 2>/dev/null)
      current=${current%...*}

      if [[ $current != 'HEAD' && $current != 'master' ]]; then
        suffix+=", branch: $current"
      fi

      builtin cd $oldPWD
      builtin unset oldPWD
    fi

    # If --tag is specified, get the current checked-out tag
    # for the package and print it alongside the name
    if [[ -n $tag ]] && _zulu_info_is_installed $package; then
      local oldPWD=$PWD
      builtin cd "$base/packages/$package"

      local commit=$(command git status HEAD -uno --ignore-submodules=all | command head -1 | command awk '{print $4}' 2>/dev/null)

      if [[ -n $commit ]]; then
        suffix+=", tag: $commit"
      fi

      builtin cd $oldPWD
      builtin unset oldPWD
    fi

    # Restore the previous ZVM_AUTO_USE setting
    export ZVM_AUTO_USE=$old_ZVM_AUTO_USE
    builtin unset old_ZVM_AUTO_USE

    # Print out the name of the package, and the installed flag
    # unless --simple is passed
    if [[ -n $simple ]]; then
      name="$package$suffix"
      lim=30
    else
      if _zulu_info_is_installed $package; then
        name="$(_zulu_color green '✔') $package$suffix"
        lim=42
      else
        name="  $package$suffix"
        lim=30
      fi
    fi

    # If --describe is specified, print the description
    if [[ -n $describe ]]; then
      description=$(jsonval $json 'description')
      builtin printf '%s' "$name"
      builtin printf '%*.*s' 0 $(($lim - ${#name} )) "$(builtin printf '%0.1s' " "{1..60})"
      builtin printf '%s\n' "$description"
    else
      builtin echo $name
    fi
  done

  return
}

###
# The main zulu list function
###
function _zulu_list() {
  local help all installed not_installed describe simple package_type branch tag

  # If no arguments are passed, just print a simple list
  # of all installed packages
  if [[ $# -eq 0 ]]; then
    installed=true
    simple=true
    _zulu_list_packages
    return
  fi

  # Parse options
  builtin zparseopts -D \
    h=help -help=help \
    i=installed -installed=installed \
    n=not_installed -not-installed=not_installed \
    a=all -all=all \
    d=describe -describe=describe \
    s=simple -simple=simple \
    t:=package_type -type:=package_type \
    -branch=branch \
    -tag=tag

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_list_usage
    return
  fi

  # Check if the --type option is passed and shift the argument
  if [[ -n $package_type ]]; then
    builtin shift package_type
  fi

  # List the packages
  _zulu_list_packages
}
