###
# Output usage information
###
function _zulu_theme_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu theme <theme_name>"
}

_zulu_theme() {
  local base theme config config_dir

  theme="$1"

  # Parse options
  zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_theme_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config_dir=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  config="${config_dir}/theme"

  echo "$theme" >! $config

  # Ensure promptinit is loaded
  autoload -U promptinit && promptinit

  # Test if theme prompt function exists.
  # If not, print a pretty warn message.
  if which prompt_${theme}_setup >/dev/null 2>&1; then
    prompt ${theme}
    return
  fi

  echo $(color red "Failed to load theme '${theme}'")
  echo "Please ensure your theme is in \$fpath and is called prompt_${theme}_setup"
  return 1
}
