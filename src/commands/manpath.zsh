###
# Output usage information
###
function _zulu_manpath_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu manpath <context> <dir>"
  builtin echo
  builtin echo $(_zulu_color yellow "Context:")
  builtin echo "  add <dir>   Add a directory to \$manpath"
  builtin echo "  reset       Replace the current session \$manpath with the stored dirs"
  builtin echo "  rm <dir>    Remove a directory from \$manpath"
}

###
# Check the existence of a directory when passed as an argument,
# and convert relative paths to absolute
###
function _zulu_manpath_parse() {
  local dir="$1" check_existing="$2"

  if [[ -d "$PWD/$dir" ]]; then
    # If the directory exists in the current working directory
    # convert the relative path to absolute
    builtin echo "$PWD/$dir"
  elif [[ -d "$dir" ]]; then
    # If the directory exists as an absolute path, we can use it directly
    builtin echo "$dir"
  elif [[ "$check_existing" != "false" ]]; then
    # The directory could not be found
    builtin echo $dir
    return 1
  fi
}

###
# Add a directory to $manpath
###
function _zulu_manpath_add() {
  local dir p
  local -a items paths; paths=($(command cat $pathfile))

  # Check that each of the passed directories exist, and convert relative
  # paths to absolute
  for dir in "$@"; do
    dir=$(_zulu_manpath_parse "$dir")

    # If parsing returned with an error, output the error and return
    if [[ $? -eq 0 ]]; then
      # Add the directory to the array of items
      items+="$dir"

      builtin echo "$(_zulu_color green '✔') $dir added to \$manpath"
    else
      builtin echo "$(_zulu_color red '✘') $dir cannot be found"
    fi

  done

  # Loop through each of the existing paths and add those to the array as well
  for p in "$paths[@]"; do
    items+="$p"
  done

  # Store the new paths in the pathfile, and override $manpath
  _zulu_manpath_store
  _zulu_manpath_reset
}

###
# Remove a directory from $manpath
###
function _zulu_manpath_rm() {
  local dir p
  local -a items paths; paths=($(command cat $pathfile))

  # Check that each of the passed directories exist, and convert relative
  # paths to absolute
  for dir in "$@"; do
    dir=$(_zulu_manpath_parse "$dir" "false")

    # If parsing returned with an error, output the error and return
    if [[ ! $? -eq 0 ]]; then
      builtin echo $dir
      return 1
    fi

    # Loop through each of the paths, and if they are *not* an exact match,
    # we want to keep them
    for p in "$paths[@]"; do
      if [[ "$p" != "$dir" ]]; then
        items+="$p"
      fi
    done

    builtin echo "$(_zulu_color green '✔') $dir removed from \$manpath"
  done

  # Store the new paths in the pathfile, and override $manpath
  _zulu_manpath_store
  _zulu_manpath_reset
}

###
# Store an array of paths in the pathfile
###
function _zulu_manpath_store() {
  local separator out

  # Separate the array by newlines, and print the contents to the pathfile
  separator=$'\n'
  local oldIFS=$IFS
  IFS="$separator"; out="${items[*]/#/${separator}}"
  builtin echo ${out:${#separator}} >! $pathfile
  IFS=$oldIFS
  builtin unset oldIFS
}

###
# Override the $manpath variable with the current contents of the pathfile
###
function _zulu_manpath_reset() {
  local separator out
  local -a paths; paths=($(command cat $pathfile))

  typeset -gUa manpath; manpath=()
  for p in "${paths[@]}"; do
    manpath+="$p"
  done
}

###
# Zulu command to handle path manipulation
###
function _zulu_manpath() {
  local ctx base pathfile

  # Parse options
  builtin zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_manpath_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  pathfile="${config}/manpath"

  if [[ ! -f "$pathfile" ]]; then
    touch $pathfile
  fi

  # If no context is passed, output the contents of the pathfile
  if [[ "$1" = "" ]]; then
    command cat "$pathfile"
    return
  fi

  # Get the context
  ctx="$1"

  # Call the relevant function
  _zulu_manpath_${ctx} "${(@)@:2}"
}
