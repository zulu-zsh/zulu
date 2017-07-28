###
# Output usage information
###
function _zulu_alias_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu alias <context> [args]"
  builtin echo
  builtin echo $(_zulu_color yellow "Contexts:")
  builtin echo "  add <alias> <command>   Add an alias"
  builtin echo "  load                    Load all aliases from alias file"
  builtin echo "  rm <alias>              Remove an alias"
}

###
# Add an alias
###
function _zulu_alias_add() {
  local existing alias cmd flag global

  builtin zparseopts -D \
    g=global -global=global

  alias="$1"
  cmd="${(@)@:2}"

  existing=$(command cat $aliasfile | command grep -E -e "^alias(\ -g)?\ $alias=")
  if [[ $existing != "" ]]; then
    builtin echo $(_zulu_color red "Alias '$alias' already exists")
    return 1
  fi

  if [[ -n $global ]]; then
    flag=' -g'
  fi

  builtin echo "alias$flag $alias='$cmd'" >> $aliasfile

  zulu alias load
  builtin echo "$(_zulu_color green '✔') Alias '$alias' added"
}

###
# Remove an alias
###
function _zulu_alias_rm() {
  local existing alias

  alias="$1"

  existing=$(command cat $aliasfile | command grep -E -e "^alias(\ -g)?\ $alias=")
  if [[ -z $existing ]]; then
    builtin echo $(_zulu_color red "Alias '$alias' does not exist")
    return 1
  fi

  builtin echo "$(command cat $aliasfile | command grep -E -ve "^alias(\ -g)?\ $alias=")" >! $aliasfile
  unalias $alias

  zulu alias load
  builtin echo "$(_zulu_color green '✔') Alias '$alias' removed"
}

###
# Load aliases
###
function _zulu_alias_load() {
  builtin source $aliasfile
}

###
# Zulu command to handle path manipulation
###
function _zulu_alias() {
  local ctx base aliasfile

  # Parse options
  builtin zparseopts -D h=help -help=help

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
