###
# Output usage information
###
function _zulu_func_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu func <context>"
  echo
  echo $(_zulu_color yellow "Contexts:")
  echo "  add <function>    Add a function"
  echo "  edit <function>   Edit a function"
  echo "  load              Load all functions from functions directory"
  echo "  rm <function>     Remove a function"
}

###
# Add a function
###
_zulu_func_add() {
  local existing func cmd

  func="$1"

  if [[ -z $EDITOR ]]; then
    echo $(_zulu_color red "The \$EDITOR environment variable must be set to use the func command in add or edit context")
    return 1
  fi

  if [[ -f "$funcdir/$func" ]]; then
    echo $(_zulu_color red "Function '$func' already exists")
    return 1
  fi

  echo "#!/usr/bin/env zsh

(( \$+functions[$func] )) || function $func() {

}" > "$funcdir/$func"

  ${=EDITOR} "$funcdir/$func"

  zulu func load
  return
}

###
# Add a function
###
_zulu_func_edit() {
  local existing func cmd

  func="$1"

  if [[ -z $EDITOR ]]; then
    echo $(_zulu_color red "The \$EDITOR environment variable must be set to use the func command in add or edit context")
    return 1
  fi

  if [[ ! -f "$funcdir/$func" ]]; then
    echo $(_zulu_color red "Function '$func' does not exist")
    return 1
  fi

  ${=EDITOR} "$funcdir/$func"

  zulu func load
  return
}

###
# Remove a function
###
_zulu_func_rm() {
  local existing func

  func="$1"

  if [[ ! -f "$funcdir/$func" ]]; then
    echo $(_zulu_color red "Function '$alias' does not exist")
    return 1
  fi

  unfunction $func
  rm "$funcdir/$func"
  zulu func load
  return
}

###
# Load aliases
###
_zulu_func_load() {
  for f in $(ls $funcdir); do
    (( $+functions[$f] )) && unfunction $f
    source "$funcdir/$f"
  done
}

###
# Zulu command to handle managing functions
###
function _zulu_func() {
  local ctx base funcdir

  # Parse options
  zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_func_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  funcdir="${config}/functions"

  # Check for and create the directory, since it will not
  # exist in older versions of Zulu
  if [[ ! -d "$funcdir" ]]; then
    mkdir -p "$funcdir"
  fi

  # If no context is passed, output the contents of the aliasfile
  if [[ "$1" = "" ]]; then
    ls "$funcdir"
    return
  fi

  # Get the context
  ctx="$1"

  # Call the relevant function
  _zulu_func_${ctx} "${(@)@:2}"
}
