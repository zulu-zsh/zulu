function _zulu_init_usage() {
  builtin echo $(_zulu_color yellow "Usage:")
  builtin echo "  zulu init [options]"
  builtin echo
  builtin echo $(_zulu_color yellow "Options:")
  builtin echo "  -c, --check-for-update   Check for updates on startup"
  builtin echo "  -h, --help               Output this help text and exit"
  builtin echo "  -n, --no-compile         Skip compilation of scripts on startup"
  builtin echo "      --dev                Start Zulu in Development Mode"
}

function _zulu_init_setup_completion() {
  #
  # Sets completion options.
  #
  # Authors:
  #   Robby Russell <robby@planetargon.com>
  #   Sorin Ionescu <sorin.ionescu@gmail.com>
  #

  # Return if requirements are not found.
  if [[ "$TERM" == 'dumb' ]]; then
    return 1
  fi

  # Load and initialize the completion system ignoring insecure directories.
  builtin autoload -Uz compinit && compinit -i

  #
  # Options
  #

  builtin setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
  builtin setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
  builtin setopt PATH_DIRS           # Perform path search even on command names with slashes.
  builtin setopt AUTO_MENU           # Show completion menu on a successive tab press.
  builtin setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
  builtin setopt AUTO_PARAM_SLASH    # If completed parameter is a directory, add a trailing slash.
  builtin unsetopt MENU_COMPLETE     # Do not autoselect the first completion entry.
  builtin unsetopt FLOW_CONTROL      # Disable start/stop characters in shell editor.

  #
  # Styles
  #

  # Use caching to make completion for commands such as dpkg and apt usable.
  builtin zstyle ':completion::complete:*' use-cache on
  builtin zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache"

  # Disable case sensitivity
  builtin zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  builtin unsetopt CASE_GLOB

  # Group matches and describe.
  builtin zstyle ':completion:*:*:*:*:*' menu select
  builtin zstyle ':completion:*:matches' group 'yes'
  builtin zstyle ':completion:*:options' description 'yes'
  builtin zstyle ':completion:*:options' auto-description '%d'
  builtin zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
  builtin zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
  builtin zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
  builtin zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
  builtin zstyle ':completion:*:default' list-prompt '%S%M matches%s'
  builtin zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
  builtin zstyle ':completion:*' group-name ''
  builtin zstyle ':completion:*' verbose yes

  # Don't show already completed options in the list
  builtin zstyle ':completion:*:*:*:*:*' ignore-line 'yes'

  # Fuzzy match mistyped completions.
  builtin zstyle ':completion:*' completer _complete _match _approximate
  builtin zstyle ':completion:*:match:*' original only
  builtin zstyle ':completion:*:approximate:*' max-errors 1 numeric

  # Increase the number of errors based on the length of the typed word.
  builtin zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

  # Don't complete unavailable commands.
  builtin zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

  # Array completion element sorting.
  builtin zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

  # Directories
  builtin zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
  builtin zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
  builtin zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
  builtin zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
  builtin zstyle ':completion:*' squeeze-slashes true

  # History
  builtin zstyle ':completion:*:history-words' stop yes
  builtin zstyle ':completion:*:history-words' remove-all-dups yes
  builtin zstyle ':completion:*:history-words' list false
  builtin zstyle ':completion:*:history-words' menu yes

  # Environmental Variables
  builtin zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

  # Populate hostname completion.
  builtin zstyle -e ':completion:*:hosts' hosts 'reply=(
    ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
    ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
    ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
  )'

  # Don't complete uninteresting users...
  builtin zstyle ':completion:*:*:*:users' ignored-patterns \
    adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
    dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
    hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
    mailman mailnull mldonkey mysql nagios \
    named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
    operator pcap postfix postgres privoxy pulse pvm quagga radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

  # ... unless we really want to.
  builtin zstyle '*' single-ignored show

  # Ignore multiple entries.
  builtin zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
  builtin zstyle ':completion:*:rm:*' file-patterns '*:all-files'

  # Kill
  builtin zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
  builtin zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
  builtin zstyle ':completion:*:*:kill:*' menu yes select
  builtin zstyle ':completion:*:*:kill:*' force-list always
  builtin zstyle ':completion:*:*:kill:*' insert-ids single

  # Man
  builtin zstyle ':completion:*:manuals' separate-sections true
  builtin zstyle ':completion:*:manuals.(^1*)' insert-sections true

  # Media Players
  builtin zstyle ':completion:*:*:mpg123:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
  builtin zstyle ':completion:*:*:mpg321:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
  builtin zstyle ':completion:*:*:ogg123:*' file-patterns '*.(ogg|OGG|flac):ogg\ files *(-/):directories'
  builtin zstyle ':completion:*:*:mocp:*' file-patterns '*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg\ files *(-/):directories'

  # Mutt
  if [[ -s "$HOME/.mutt/aliases" ]]; then
    builtin zstyle ':completion:*:*:mutt:*' menu yes select
    builtin zstyle ':completion:*:mutt:*' users ${${${(f)"$(<"$HOME/.mutt/aliases")"}#alias[[:space:]]}%%[[:space:]]*}
  fi

  # SSH/SCP/RSYNC
  builtin zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
  builtin zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
  builtin zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
  builtin zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
  builtin zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
  builtin zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
  builtin zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
}

function _zulu_init_setup_history() {
  #
  # Variables
  #

  HISTFILE="${ZDOTDIR:-$HOME}/.zhistory"       # The path to the history file.
  HISTSIZE=10000                   # The maximum number of events to save in the internal history.
  SAVEHIST=10000                   # The maximum number of events to save in the history file.

  #
  # Options
  #

  builtin setopt BANG_HIST                 # Treat the '!' character specially during expansion.
  builtin setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
  builtin setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
  builtin setopt SHARE_HISTORY             # Share history between all sessions.
  builtin setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
  builtin setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
  builtin setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
  builtin setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
  builtin setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
  builtin setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
  builtin setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
  builtin setopt HIST_BEEP                 # Beep when accessing non-existent history.

  if (( $+widgets[history-substring-search-up] )); then
    #
    # Integrates history-substring-search into Prezto.
    #
    # Authors:
    #   Suraj N. Kurapati <sunaku@gmail.com>
    #   Sorin Ionescu <sorin.ionescu@gmail.com>
    #

    # Source module files.
    [[ -f "$base/init/zsh-history-substring-search.zsh" ]] || return 1

    builtin zle -N history-substring-search-up
    builtin zle -N history-substring-search-down

    #
    # Search
    #

    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=magenta,fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=red,fg=white,bold'
    HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
    HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS="${HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS//i}"

    #
    # Key Bindings
    #

    if [[ -n "$key_info" ]]; then
      # Emacs
      builtin bindkey -M emacs "$key_info[Control]P" history-substring-search-up
      builtin bindkey -M emacs "$key_info[Control]N" history-substring-search-down

      # Vi
      builtin bindkey -M vicmd "k" history-substring-search-up
      builtin bindkey -M vicmd "j" history-substring-search-down

      # Emacs and Vi
      for keymap in 'emacs' 'viins'; do
        builtin bindkey -M "$keymap" "$key_info[Up]" history-substring-search-up
        builtin bindkey -M "$keymap" "$key_info[Down]" history-substring-search-down
      done
    fi
  fi
}

function _zulu_init_setup_key_bindings() {
  #
  # Sets key bindings.
  #
  # Authors:
  #   Sorin Ionescu <sorin.ionescu@gmail.com>
  #

  # Return if requirements are not found.
  if [[ "$TERM" == 'dumb' ]]; then
    return 1
  fi

  #
  # Options
  #

  # Beep on error in line editor.
  builtin setopt BEEP

  #
  # Variables
  #

  # Treat these characters as part of a word.
  WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

  # Use human-friendly identifiers.
  builtin zmodload zsh/terminfo
  typeset -gA key_info
  key_info=(
    'Control'      '\C-'
    'ControlLeft'  '\e[1;5D \e[5D \e\e[D \eOd'
    'ControlRight' '\e[1;5C \e[5C \e\e[C \eOc'
    'Escape'       '\e'
    'Meta'         '\M-'
    'Backspace'    "^?"
    'Delete'       "^[[3~"
    'F1'           "$terminfo[kf1]"
    'F2'           "$terminfo[kf2]"
    'F3'           "$terminfo[kf3]"
    'F4'           "$terminfo[kf4]"
    'F5'           "$terminfo[kf5]"
    'F6'           "$terminfo[kf6]"
    'F7'           "$terminfo[kf7]"
    'F8'           "$terminfo[kf8]"
    'F9'           "$terminfo[kf9]"
    'F10'          "$terminfo[kf10]"
    'F11'          "$terminfo[kf11]"
    'F12'          "$terminfo[kf12]"
    'Insert'       "$terminfo[kich1]"
    'Home'         "$terminfo[khome]"
    'PageUp'       "$terminfo[kpp]"
    'End'          "$terminfo[kend]"
    'PageDown'     "$terminfo[knp]"
    'Up'           "^[[A"
    'Left'         "^[[D"
    'Down'         "^[[B"
    'Right'        "^[[C"
    'BackTab'      "$terminfo[kcbt]"
  )

  # Set empty $key_info values to an invalid UTF-8 sequence to induce silent
  # bindkey failure.
  for key in "${(k)key_info[@]}"; do
    if [[ -z "$key_info[$key]" ]]; then
      key_info[$key]='�'
    fi
  done

  #
  # External Editor
  #

  # Allow command line editing in an external editor.
  builtin autoload -Uz edit-command-line
  builtin zle -N edit-command-line

  #
  # Functions
  #

  # Exposes information about the Zsh Line Editor via the $editor_info associative
  # array.
  function editor-info {
    builtin zle reset-prompt
    builtin zle -R
  }
  builtin zle -N editor-info

  # Updates editor information when the keymap changes.
  function zle-keymap-select {
    builtin zle editor-info
  }
  builtin zle -N zle-keymap-select

  # Enables terminal application mode and updates editor information.
  function zle-line-init {
    # The terminal must be in application mode when ZLE is active for $terminfo
    # values to be valid.
    if (( $+terminfo[smkx] )); then
      # Enable terminal application mode.
      echoti smkx
    fi

    # Update editor information.
    builtin zle editor-info
  }
  builtin zle -N zle-line-init

  # Disables terminal application mode and updates editor information.
  function zle-line-finish {
    # The terminal must be in application mode when ZLE is active for $terminfo
    # values to be valid.
    if (( $+terminfo[rmkx] )); then
      # Disable terminal application mode.
      echoti rmkx
    fi

    # Update editor information.
    builtin zle editor-info
  }
  builtin zle -N zle-line-finish

  # Toggles emacs overwrite mode and updates editor information.
  function overwrite-mode {
    builtin zle .overwrite-mode
    builtin zle editor-info
  }
  builtin zle -N overwrite-mode

  # Enters vi insert mode and updates editor information.
  function vi-insert {
    builtin zle .vi-insert
    builtin zle editor-info
  }
  builtin zle -N vi-insert

  # Moves to the first non-blank character then enters vi insert mode and updates
  # editor information.
  function vi-insert-bol {
    builtin zle .vi-insert-bol
    builtin zle editor-info
  }
  builtin zle -N vi-insert-bol

  # Enters vi replace mode and updates editor information.
  function vi-replace  {
    builtin zle .vi-replace
    builtin zle editor-info
  }
  builtin zle -N vi-replace

  # Expands .... to ../..
  function expand-dot-to-parent-directory-path {
    if [[ $LBUFFER = *.. ]]; then
      LBUFFER+='/..'
    else
      LBUFFER+='.'
    fi
  }
  builtin zle -N expand-dot-to-parent-directory-path

  # Displays an indicator when completing.
  function expand-or-complete-with-indicator {
    local indicator="→"
    print -Pn "$indicator"
    builtin zle expand-or-complete
    builtin zle redisplay
  }
  builtin zle -N expand-or-complete-with-indicator

  # Inserts 'sudo ' at the beginning of the line.
  function prepend-sudo {
    if [[ "$BUFFER" != su(do|)\ * ]]; then
      BUFFER="sudo $BUFFER"
      (( CURSOR += 5 ))
    fi
  }
  builtin zle -N prepend-sudo

  # Reset to default key bindings.
  builtin bindkey -d

  #
  # Emacs Key Bindings
  #

  for key in "$key_info[Escape]"{B,b} "${(s: :)key_info[ControlLeft]}"
    builtin bindkey -M emacs "$key" emacs-backward-word
  for key in "$key_info[Escape]"{F,f} "${(s: :)key_info[ControlRight]}"
    builtin bindkey -M emacs "$key" emacs-forward-word

  # Kill to the beginning of the line.
  for key in "$key_info[Escape]"{K,k}
    builtin bindkey -M emacs "$key" backward-kill-line

  # Redo.
  builtin bindkey -M emacs "$key_info[Escape]_" redo

  # Search previous character.
  builtin bindkey -M emacs "$key_info[Control]X$key_info[Control]B" vi-find-prev-char

  # Match bracket.
  builtin bindkey -M emacs "$key_info[Control]X$key_info[Control]]" vi-match-bracket

  # Edit command in an external editor.
  builtin bindkey -M emacs "$key_info[Control]X$key_info[Control]E" edit-command-line

  if (( $+widgets[history-incremental-pattern-search-backward] )); then
    builtin bindkey -M emacs "$key_info[Control]R" \
      history-incremental-pattern-search-backward
    builtin bindkey -M emacs "$key_info[Control]S" \
      history-incremental-pattern-search-forward
  fi

  #
  # Vi Key Bindings
  #

  # Edit command in an external editor.
  builtin bindkey -M vicmd "v" edit-command-line

  # Undo/Redo
  builtin bindkey -M vicmd "u" undo
  builtin bindkey -M vicmd "$key_info[Control]R" redo

  if (( $+widgets[history-incremental-pattern-search-backward] )); then
    builtin bindkey -M vicmd "?" history-incremental-pattern-search-backward
    builtin bindkey -M vicmd "/" history-incremental-pattern-search-forward
  else
    builtin bindkey -M vicmd "?" history-incremental-search-backward
    builtin bindkey -M vicmd "/" history-incremental-search-forward
  fi

  #
  # Emacs and Vi Key Bindings
  #

  for keymap in 'emacs' 'viins'; do
    builtin bindkey -M "$keymap" "$key_info[Home]" beginning-of-line
    builtin bindkey -M "$keymap" "$key_info[End]" end-of-line

    builtin bindkey -M "$keymap" "$key_info[Insert]" overwrite-mode
    builtin bindkey -M "$keymap" "$key_info[Delete]" delete-char
    builtin bindkey -M "$keymap" "$key_info[Backspace]" backward-delete-char

    builtin bindkey -M "$keymap" "$key_info[Left]" backward-char
    builtin bindkey -M "$keymap" "$key_info[Right]" forward-char

    # Expand history on space.
    builtin bindkey -M "$keymap" ' ' magic-space

    # Clear screen.
    builtin bindkey -M "$keymap" "$key_info[Control]L" clear-screen

    # Expand command name to full path.
    for key in "$key_info[Escape]"{E,e}
      builtin bindkey -M "$keymap" "$key" expand-cmd-path

    # Duplicate the previous word.
    for key in "$key_info[Escape]"{M,m}
      builtin bindkey -M "$keymap" "$key" copy-prev-shell-word

    # Use a more flexible push-line.
    for key in "$key_info[Control]Q" "$key_info[Escape]"{q,Q}
      builtin bindkey -M "$keymap" "$key" push-line-or-edit

    # Bind Shift + Tab to go to the previous menu item.
    builtin bindkey -M "$keymap" "$key_info[BackTab]" reverse-menu-complete

    # Complete in the middle of word.
    builtin bindkey -M "$keymap" "$key_info[Control]I" expand-or-complete

    # Expand .... to ../..
    builtin bindkey -M "$keymap" "." expand-dot-to-parent-directory-path

    # Display an indicator when completing.
    builtin bindkey -M "$keymap" "$key_info[Control]I" \
      expand-or-complete-with-indicator

    # Insert 'sudo ' at the beginning of the line.
    builtin bindkey -M "$keymap" "$key_info[Control]X$key_info[Control]S" prepend-sudo
  done

  builtin unset key{,map,bindings}
}

###
# Check for updates
###
function _zulu_check_for_update() {
  local out
  local -a commands pids

  commands=(
    '_zulu_self-update_check_for_update'
    '_zulu_update_check_for_update'
    '_zulu_upgrade --check'
  )

  # If the ZSH version we are using supports it,
  # perform update checks asynchronously
  if is-at-least '5.1'; then
    pids=()

    for command in $commands; do
      {
        out=$(${=command})
        if [[ $? -eq 0 ]]; then
          builtin echo $out
        fi
      } &!
      pids+=$!
    done

    for pid in $pids; do
      while builtin kill -0 $pid >/dev/null 2>&1; do
      done
    done
  else
    for command in $commands; do
      out=$(${=command})
      if [[ $? -eq 0 ]]; then
        builtin echo $out
      fi
    done
  fi
}

###
# Source init scripts for installed packages
###
function _zulu_load_packages() {
  # Source files in the init directory
  builtin setopt EXTENDED_GLOB
  for f in ${base}/init/**/*^(*.zwc)(#q@N); do
    if [[ -L $f ]]; then
      builtin source $(command readlink $f)
    else
      builtin source $f
    fi
  done
}

###
# Use Zulu next
###
function _zulu_init_switch_branch() {
  local oldPWD=$PWD branch="$1"
  builtin cd $base/core

  local current=$(command git status --short --branch -uno --ignore-submodules=all | command head -1 | command awk '{print $2}' 2>/dev/null)

  if [[ ${current:0:${#branch}} != $branch ]]; then
    command git reset --hard >/dev/null 2>&1
    command git checkout $branch >/dev/null 2>&1
    ./build.zsh >/dev/null 2>&1
    builtin source ./zulu
    builtin echo "\033[0;32m✔\033[0;m Switched to Zulu ${branch}"
  fi

  builtin cd $oldPWD
  builtin unset oldPWD
}

###
# Display a message to next users
###
function _zulu_init_next_message() {
  builtin echo
  builtin echo '\033[0;33mThanks for using Zulu next\033[0;m'
  builtin echo 'We rely on people like you testing new versions to keep Zulu as useful'
  builtin echo 'and as stable as possible. If you do run into any errors, please do'
  builtin echo 'report them so that they can be fixed before the next release.'
  builtin echo
  builtin echo 'Github Issues: https://github.com/zulu-zsh/zulu/issues'
  builtin echo 'Gitter Chat:   https://gitter.im/zulu-zsh/zulu'
}

###
# Set up the zulu environment
###
function _zulu_init() {
  local base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  local config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  local help check_for_update no_compile next dev

  # Parse CLI options
  builtin zparseopts -D \
    h=help -help=help \
    c=check_for_update -check-for-update=check_for_update \
    n=no_compile -no-compile=no_compile \
    -next=next \
    -dev=dev

  if [[ -n $help ]]; then
    _zulu_init_usage
    return
  fi

  # Check for the --dev flag and turn dev mode on or off
  if [[ -n $dev ]]; then
    export ZULU_DEV_MODE=1
  else
    export ZULU_DEV_MODE=0
  fi

  # Check for the --next flag unless in dev mode
  if [[ $ZULU_DEV_MODE -ne 1 ]]; then
    if [[ -n $next ]]; then
      _zulu_init_switch_branch 'next'
    else
      _zulu_init_switch_branch 'master'
    fi
  fi

  # Populate paths
  zulu path reset
  zulu fpath reset
  zulu cdpath reset
  zulu manpath reset

  # Set up the environment
  _zulu_init_setup_key_bindings
  _zulu_init_setup_completion

  # Load installed packages
  _zulu_load_packages

  # Set up history
  _zulu_init_setup_history

  # Load aliases, functions and environment variables
  zulu alias load
  zulu func load
  zulu var load

  # Autoload zsh theme
  if [[ -f "$config/theme" ]]; then
    builtin autoload -U promptinit && promptinit
    local theme=$(cat "$config/theme")
    prompt $theme
  fi

  if [[ -z $no_compile ]]; then
    {
      zulu compile
    } >/dev/null 2>&1 &!
  fi

  [[ -n $check_for_update ]] && _zulu_check_for_update

  # If Zulu next is enabled, show a message to the user
  if [[ -n $next ]]; then
    _zulu_init_next_message
  fi

  return
}
