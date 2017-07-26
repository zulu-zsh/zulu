###
# Output usage information
###
function _zulu_search_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu search <term>"
}

###
# Zulu command to search the package index
###
function _zulu_search() {
  local base index out results term=$1

  # Parse options
  builtin zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_search_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  index="${base}/index/packages"

  results="$(zulu list --all | command grep -i $term)"
  builtin echo "$results"
}
