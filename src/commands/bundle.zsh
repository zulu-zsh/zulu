###
# Print usage information
###
function _zulu_bundle_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu bundle [options]"
  echo
  echo $(_zulu_color yellow "Options:")
  echo "  -c, --cleanup        Uninstall packages not in packagefile"
  echo "  -f, --file           Specify a packagefile"
  echo "  -d, --dump           Dump installed packages to packagefile"
  echo "  -h, --help           Output this help text and exit"
  echo "  -x, --force          Force writing of packages to an existing file"
}

###
# Dump installed packages to file
###
function _zulu_bundle_dump() {
  local installed=$(zulu list --installed --simple --branch --tag)

  # Check if the packagefile exists
  if [[ -f $packagefile ]]; then
    # If the --force option was passed, overwrite it
    if [[ -n $force ]]; then
      echo "$installed" >! $packagefile
      return
    fi

    # Throw an error
    echo $(_zulu_color red "Packagefile at $packagefile already exists")
    echo 'Use `zulu bundle --dump --force` to overwrite'
    return 1
  fi

  # Write to the packagefile
  echo "$installed" > $packagefile
  return
}

###
# Uninstall packages not in packagefile
###
function _zulu_bundle_cleanup() {
  local -a installed; installed=($(zulu list --installed --simple))

  # Loop through each of the installed packages
  for package in "${installed[@]}"; do
    # Search the packagefile
    check=$(cat $packagefile | grep -e "^${package}$")

    # If not found, uninstall it
    if [[ -z $check ]]; then
      zulu uninstall $package
    fi
  done
}

###
# The zulu bundle command
###
function _zulu_bundle() {
  local help file cleanup dump force base config packagefile packages

  # Parse options
  zparseopts -D h=help -help=help \
                f:=file -file:=file \
                c=cleanup -cleanup=cleanup \
                d=dump -dump=dump \
                x=force -force=force

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_bundle_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}

  # Set the path for the default packagefile
  packagefile="$config/packages"

  # If a file is passed, use that as the packagefile
  if [[ -n $file ]]; then
    shift file
    packagefile="$file"
  fi

  # Check for the dump option
  if [[ -n $dump ]]; then
    _zulu_bundle_dump
    return $?
  fi

  # Check that the packagefile exists, and throw an
  # error if it does not
  if [[ ! -f $packagefile ]]; then
    echo $(_zulu_color red 'Packagefile cannot be found')
    return 1
  fi

  # Check for the cleanup option
  if [[ -n $cleanup ]]; then
    _zulu_bundle_cleanup
    return $?
  fi

  local oldIFS=$IFS
  IFS=$'\n'

  # Load the list of packages
  packages=($(cat $packagefile))

  IFS=$oldIFS
  unset oldIFS

  # Loop through the packages
  for package in "${packages[@]}"; do
    local package_name='' flag='' argument='' install_flags=''

    # Separate the package name from any meta information
    local -a parts meta
    parts=(${(ps/, /)package})
    package_name="${parts[1]}"
    meta=(${(ps/: /)parts[2]})

    # Skip the package if it is already installed
    if _zulu_info_is_installed $package_name; then
      continue
    fi

    # Separate the meta information into flags and arguments
    if [[ ${#meta} -gt 0 ]]; then
      flag="${meta[1]}"
      argument="${meta[2]}"

      # Create the correct install flags
      case ${flag} in
        branch )
          install_flags="--branch $argument"
          ;;
        tag )
          install_flags="--tag $argument"
          ;;
      esac
    fi

    # Install the package
    zulu install ${(ps/ /)install_flags} $package_name
  done
}
