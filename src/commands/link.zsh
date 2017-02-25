###
# Print usage information
###
function _zulu_link_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu link <package>"
  echo
  echo $(_zulu_color yellow "Options:")
  echo "      --no-autoselect-themes      Don't autoselect themes after installing"
}

###
# The zulu link function
###
function _zulu_link() {
  local help package json dir file link base index no_autoselect_themes
  local -a dirs

  zparseopts -D h=help -help=help \
    -no-autoselect-themes=no_autoselect_themes

  if [[ -n $help ]]; then
    _zulu_link_usage
    return
  fi

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="$base/index/packages"

  package="$1"

  # Check if the package is already installed
  root="$base/packages/$package"
  if [[ ! -d "$root" ]]; then
    echo $(_zulu_color red "Package '$package' is not installed")
    return 1
  fi

  _zulu_revolver start "Linking $package..."

  # Get the JSON from the index
  json=$(cat "$index/$package")

  # See if the package has a post_install script
  post_install=$(jsonval $json 'post_install')
  echo "Post install: $post_install" >&2
  if [[ -n $post_install ]]; then
    # Change to the package directory
    oldPWD=$PWD
    cd $root

    # Eval the post_install script
    output=$(eval "$post_install")
    if [[ $? -ne 0 ]]; then
      echo $(color red "Post install step for $package failed")
      echo "$output"
      cd $oldPWD
      return 1
    fi

    cd $oldPWD
  fi

  # Loop through the 'bin' and 'share' objects
  dirs=('bin' 'init' 'share')
  for dir in $dirs[@]; do
    # Reset $IFS, just in case
    local oldIFS=$IFS
    IFS=$' '

    # Convert the bin/share object into an associative array
    typeset -A files; files=($(echo $(jsonval $json $dir) | tr "," "\n" | tr ":" " "))

    IFS=$oldIFS

    # Continue on to the next directory if no files exist
    [[ ${#files} -eq 0 ]] && continue

    # Loop through each of the values in the array, the key is a file within
    # the package, the value is the name of a symlink to create in the directory
    for file link in "${(@kv)files}"; do
      # Create a symlink to the file, filtering out .zwc files
      ln -s $root/${~file} $base/$dir/$link

      # Make sure that commands to be included in bin are executable
      if [[ "$dir" = "bin" ]]; then
        chmod u+x "$root/$file"
      fi

      # Source init scripts
      if [[ "$dir" = "init" ]]; then
        source $(readlink "$base/init/$link")
      fi
    done
  done

  package_type=$(jsonval $json 'type')
  if [[ -z $no_autoselect_themes ]]; then
    if [[ $package_type = 'theme' ]]; then
      zulu theme $package
    fi
  fi

  _zulu_revolver stop
  echo "$(_zulu_color green '✔') Finished linking $package        "
}
