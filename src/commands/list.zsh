###
# Print usage information
###
function _zulu_list_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu list [options]"
  echo
  echo $(_zulu_color yellow "Options:")
  echo "  -a, --all            List all packages in the index"
  echo "  -d, --describe       Include package description in output"
  echo "  -h, --help           Output this help text and exit"
  echo "  -i, --installed      List only installed packages (default)"
  echo "  -n, --not-installed  List non-installed packages"
  echo "  -s, --simple         Hide the 'package installed' indicator"
  echo "  -t, --type <type>    Limit results to packages of <type>"
}

function _zulu_list_all() {
  local base index files json packages package type name description pad palength

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="$base/index/packages"

  for package in $(/bin/ls $index | grep -v '.md'); do
    json="$(cat $index/$package)"

    type=$(jsonval $json 'type')
    if [[ -n $package_type && $type != $package_type ]]; then
      continue
    fi

    if [[ -n $simple ]]; then
      name="$package"
      lim=30
    else
      if [[ -d "$base/packages/$package" ]]; then
        name="$(_zulu_color green '✔') $package"
        lim=36
      else
        name="  $package"
        lim=30
      fi
    fi

    if [[ -n $describe ]]; then
      description=$(jsonval $json 'description')
      printf '%s' "$name"
      printf '%*.*s' 0 $(($lim - ${#name} )) "$(printf '%0.1s' " "{1..60})"
      printf '%s\n' "$description"
    else
      echo $name
    fi
  done

  return
}

function _zulu_list_installed() {
  local base index files json packages package type description pad palength

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="$base/index/packages"

  for package in $(/bin/ls "$base/packages"); do
    json="$(cat $index/$package)"

    type=$(jsonval $json 'type')
    if [[ -n $package_type && $type != $package_type ]]; then
      continue
    fi

    if [[ -n $describe ]]; then
      description=$(jsonval $json 'description')

      printf '%s' "$package"
      printf '%*.*s' 0 $((30 - ${#package} )) "$(printf '%0.1s' " "{1..60})"
      printf '%s\n' "$description"
    else
      echo $package
    fi
  done

  return
}

function _zulu_list_not_installed() {
  local base index files json packages package type description pad palength

  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="$base/index/packages"

  for package in $(/bin/ls $index | grep -v '.md'); do
    if [[ ! -d "$base/packages/$package" ]]; then
      json="$(cat $index/$package)"

      type=$(jsonval $json 'type')
      if [[ -n $package_type && $type != $package_type ]]; then
        continue
      fi

      if [[ -n $describe ]]; then
        description=$(jsonval $json 'description')

        printf '%s' "$package"
        printf '%*.*s' 0 $((30 - ${#package} )) "$(printf '%0.1s' " "{1..60})"
        printf '%s\n' "$description"
      else
        echo $package
      fi
    fi
  done

  return
}

function _zulu_list() {
  local help all installed not_installed describe simple package_type

  # Parse options
  zparseopts -D \
    h=help -help=help \
    i=installed -installed=installed \
    n=not_installed -not-installed=not_installed \
    a=all -all=all \
    d=describe -describe=describe \
    s=simple -simple=simple \
    t:=package_type -type:=package_type

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_list_usage
    return
  fi

  if [[ -n $package_type ]]; then
    shift package_type
  fi

  if [[ -n $all ]]; then
    _zulu_list_all
    return
  fi

  if [[ -n $not_installed ]]; then
    _zulu_list_not_installed
    return
  fi

  _zulu_list_installed
}
