###
# Output usage information
###
function _zulu_var_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu var <context> [args]"
  echo
  echo $(_zulu_color yellow "Contexts:")
  echo "  add <var> <command>   Add an environment variable"
  echo "  load                  Load all environment variables from env file"
  echo "  rm <var>              Remove an environment variable"
}

###
# Add an var
###
_zulu_var_add() {
  local existing var cmd private

  zparseopts -D \
    p=private -private=private

  var="$1"
  cmd="${(@)@:2}"

  # Loop through each of the envfiles
  for file in $envfile $envfile.private; do
    # Search for the variable in the file
    existing=$(cat $file | grep "export $var=")

    # If the variable already exists in either file,
    # throw an error
    if [[ $existing != "" ]]; then
      echo $(_zulu_color red "Environment variable '$var' already exists")
      return 1
    fi
  done

  # If the variable is private, set the correct envfile to use
  if [[ -n $private ]]; then
    envfile="$envfile.private"
  fi

  # Save the variable to the envfile
  echo "export $var='$cmd'" >> $envfile

  # Strip any blank lines for neatness
  echo "$(cat $envfile | grep -vE '^\s*$')" >! $envfile

  # Reload variables
  zulu var load
  return
}

###
# Remove an var
###
_zulu_var_rm() {
  local existing var

  var="$1"

  # Loop through each of the envfiles
  for file in $envfile $envfile.private; do
    # Search for the variable in the file
    existing=$(cat $file | grep "export $var=")

    # If we haven't found it, skip to the next file
    [[ $existing = "" ]] && continue

    # If we get here, we've found the variable, so we rewrite the file,
    # stripping out the definition to remove
    echo "$(cat $file | grep -v "export $var=" | grep -vE '^\s*$')" >! $file
    break
  done

  # The variable wasn't found in either of the envfiles, so throw an error
  if [[ $existing = "" ]]; then
    echo $(_zulu_color red "Environment variable '$var' does not exist")
    return 1
  fi

  unset $var
  zulu var load
  return
}

###
# Load vares
###
_zulu_var_load() {
  source $envfile
  source $envfile.private
}

###
# Zulu command to handle path manipulation
###
function _zulu_var() {
  local ctx base envfile private

  # Parse options
  zparseopts -D h=help -help=help \
    p=private -private=private

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_var_usage
    return
  fi

  # Set up some variables
  base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  envfile="${config}/env"

  # Check if the envfiles exist, and if not create them
  [[ -f $envfile ]] || touch $envfile
  [[ -f "$envfile.private" ]] || touch "$envfile.private"

  # If no context is passed, output the contents of the envfiles
  if [[ "$1" = "" ]]; then
    cat "$envfile"
    echo
    echo $(_zulu_color yellow 'Private:')
    cat "$envfile.private"
    return
  fi

  # Get the context
  ctx="$1"
  shift

  # Call the relevant function
  _zulu_var_${ctx} ${private:+'--private'} "$@"
}
