###
# Output usage information
###
function _zulu_alias_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu alias <context> [args]"
  echo
  echo $(_zulu_color yellow "Contexts:")
  echo "  add <alias> <command>   Add an alias"
  echo "  load                    Load all aliases from alias file"
  echo "  rm <alias>              Remove an alias"
}

###
# Add an alias
###
function _zulu_alias_add() {
  local existing alias cmd

  alias="$1"
  cmd="${(@)@:2}"

  existing=$(cat $aliasfile | grep "alias $alias=")
  if [[ $existing != "" ]]; then
    echo $(_zulu_color red "Alias '$alias' already exists")
    return 1
  fi

  echo "alias $alias='$cmd'" >> $aliasfile

  zulu alias load
  echo "$(_zulu_color green '✔') Alias '$alias' added"
}

###
# Remove an alias
###
function _zulu_alias_rm() {
  local existing alias

  alias="$1"

  existing=$(cat $aliasfile | grep "alias $alias=")
  if [[ $existing = "" ]]; then
    echo $(_zulu_color red "Alias '$alias' does not exist")
    return 1
  fi

  echo "$(cat $aliasfile | grep -v "alias $alias=")" >! $aliasfile
  unalias $alias

  zulu alias load
  echo "$(_zulu_color green '✔') Alias '$alias' removed"
}

###
# Load aliases
###
function _zulu_alias_load() {
  source $aliasfile
}

###
# Zulu command to handle path manipulation
###
function _zulu_alias() {
  local ctx base aliasfile

  # Parse options
  zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_alias_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  aliasfile="${config}/alias"

  # If no context is passed, output the contents of the aliasfile
  if [[ "$1" = "" ]]; then
    cat "$aliasfile"
    return
  fi

  # Get the context
  ctx="$1"

  # Call the relevant function
  _zulu_alias_${ctx} "${(@)@:2}"
}
