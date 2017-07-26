###
# Get the value for a key in a JSON object
#
# IMPORTANT: There must be no newlines within nested objects
###
function jsonval {
  local temp json=$1 key=$2
  local oldIFS=$IFS
  IFS=$' \t\n'

  temp=$(builtin echo $json | command sed 's/\\\\\//\//g' | \
    command sed 's/[{}]//g' | \
    command sed 's/\"\:\"/\|/g' | \
    command sed 's/[\,]/ /g' | \
    command sed 's/\"//g' | \
    command grep -w $key | \
    command cut -d":" -f2-9999999 | \
    command sed -e 's/^ *//g' -e 's/ *$//g'
  )
  builtin echo ${temp##*|}

  IFS=$oldIFS
  builtin unset oldIFS
}

###
# If the revolver command is not installed, create a simple polyfill
# function to prevent COMMAND_NOT_FOUND errors
###
function _zulu_color {
  $(builtin type -p color 2>&1 > /dev/null)
  if [[ $? -ne 0 && ! -x ${ZULU_DIR:-"${ZDOTDIR:-$HOME}/bin/color"} ]]; then
    local color=$1 style=$2 b=0

    builtin shift

    case $style in
      bold|b)           b=1; builtin shift ;;
      italic|i)         b=2; builtin shift ;;
      underline|u)      b=4; builtin shift ;;
      inverse|in)       b=7; builtin shift ;;
      strikethrough|s)  b=9; builtin shift ;;
    esac

    case $color in
      black|b)    builtin echo "\033[${b};30m${@}\033[0;m" ;;
      red|r)      builtin echo "\033[${b};31m${@}\033[0;m" ;;
      green|g)    builtin echo "\033[${b};32m${@}\033[0;m" ;;
      yellow|y)   builtin echo "\033[${b};33m${@}\033[0;m" ;;
      blue|bl)    builtin echo "\033[${b};34m${@}\033[0;m" ;;
      magenta|m)  builtin echo "\033[${b};35m${@}\033[0;m" ;;
      cyan|c)     builtin echo "\033[${b};36m${@}\033[0;m" ;;
      white|w)    builtin echo "\033[${b};37m${@}\033[0;m" ;;
    esac

    return
  fi

  command color "$@"
}

###
# If the revolver command is not installed, create an empty
# function to prevent COMMAND_NOT_FOUND errors
###
function _zulu_revolver {
  if [[ $ZULU_NO_PROGRESS -eq 1 ]]; then
    return
  fi

  $(builtin type -p revolver 2>&1 > /dev/null)
  if [[ $? -ne 0 && ! -x ${ZULU_DIR:-"${ZDOTDIR:-$HOME}/bin/revolver"} ]]; then
    # Check for a revolver process file, and remove it if it exists.
    # Revolver will handle the missing state and kill any orphaned process.
    if [[ -f "${ZDOTDIR:-$HOME}/.revolver/${$}" ]]; then
      command rm "${ZDOTDIR:-$HOME}/.revolver/${$}"
    fi
    return
  fi

  command revolver "$@"
}
