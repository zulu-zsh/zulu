###
# Output usage information
###
function _zulu_theme_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu theme <theme_name>"
}

_zulu_theme() {
  local base theme config config_dir

  theme="$1"

  # Parse options
  builtin zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_theme_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config_dir=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  config="${config_dir}/theme"

  # If no argument is passed, print the current theme
  if [[ -z $theme ]]; then
    echo "$(cat $config)"
    return
  fi

  # Ensure promptinit is loaded
  autoload -U promptinit && promptinit

  # Test if theme prompt function exists.
  # If not, print a pretty warn message.
  if builtin which prompt_${theme}_setup >/dev/null 2>&1; then
    prompt ${theme}
    if [[ $? -eq 0 ]]; then
      builtin echo "$theme" >! $config
      builtin echo "$(_zulu_color green '✔') Theme set to $theme"
      return
    fi
  fi

  builtin echo $(_zulu_color red "Failed to load theme '${theme}'")
  builtin echo "Please ensure your theme is in \$fpath and is called prompt_${theme}_setup"
  return 1
}
