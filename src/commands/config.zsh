###
# Output usage information
###
function _zulu_config_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu config <args...>"
  echo
  echo $(_zulu_color yellow "Contexts:")
  echo "  list                List all config values"
  echo "  get <key>           Get a config value"
  echo "  set <key> <value>   Set a config value"
}

###
# Set a config value
###
function _zulu_config_set() {
  local key="$1" value="${(@)@:2}"

  _zulu_config_load

  # Rewrite the config file, omitting the key
  # we're setting if it exists
  echo $(cat $configfile | grep -v -E "^$key:") >! $configfile

  # Write the new value to the config file
  echo "$key: $value" >> $configfile

  # Write the config file again, stripping out any blank lines
  echo $(cat $configfile | grep -v -E '^\s*$') >! $configfile

  zulu config $key
}

###
# Get a config value
###
function _zulu_config_get() {
  local key="$1"

  _zulu_config_load

  if (( ! $+zulu_config[$key] )); then
    return 1
  fi

  echo "$zulu_config[$key]"
}

###
# Load the current config
###
function _zulu_config_load {
  [[ ! -f $configfile ]] && touch $configfile
  eval $(_zulu_config_parse_yaml)
}

###
# Parse the YAML config file
# Based on https://gist.github.com/pkuczynski/8665367
###
function _zulu_config_parse_yaml() {
  local s w fs prefix='zulu_config'
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @|tr @ '\034')"
  sed -ne "s|^\(${s}\)\(${w}\)${s}:${s}\"\(.*\)\"${s}\$|\1${fs}\2${fs}\3|p" \
      -e "s|^\(${s}\)\(${w}\)${s}[:-]${s}\(.*\)${s}\$|\1${fs}\2${fs}\3|p" "$configfile" |
  awk -F"${fs}" '{
  indent = length($1)/2;
  vname[indent] = $2;
  for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
          vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
          printf("%s%s[%s]=\"%s\"\n", "'"$prefix"'",vn, $2, $3);
      }
  }' | sed 's/_=/+=/g'
}

###
# Zulu command to handle configuration
###
function _zulu_config() {
  local ctx
  local configfile="${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}/config.yml"

  zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_var_usage
    return
  fi

  typeset -A zulu_config

  ctx="$1"
  case $ctx in
    list )
      cat $configfile
      ;;
    set )
      _zulu_config_set "${(@)@:2}"
      ;;
    * )
      _zulu_config_get "$@"
      ;;
  esac
}
