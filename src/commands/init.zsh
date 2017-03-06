function _zulu_init_usage() {
  echo $(_zulu_color yellow "Usage:")
  echo "  zulu init [options]"
  echo
  echo $(_zulu_color yellow "Options:")
  echo "  -c, --check-for-update   Check for updates on startup"
  echo "  -h, --help               Output this help text and exit"
  echo "  -n, --no-compile         Skip compilation of scripts on startup"
  echo "      --dev                Start Zulu in Development Mode"
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
  autoload -Uz compinit && compinit -i

  #
  # Options
  #

  setopt COMPLETE_IN_WORD    # Complete from both ends of a word.
  setopt ALWAYS_TO_END       # Move cursor to the end of a completed word.
  setopt PATH_DIRS           # Perform path search even on command names with slashes.
  setopt AUTO_MENU           # Show completion menu on a successive tab press.
  setopt AUTO_LIST           # Automatically list choices on ambiguous completion.
  setopt AUTO_PARAM_SLASH    # If completed parameter is a directory, add a trailing slash.
  unsetopt MENU_COMPLETE     # Do not autoselect the first completion entry.
  unsetopt FLOW_CONTROL      # Disable start/stop characters in shell editor.

  #
  # Styles
  #

  # Use caching to make completion for commands such as dpkg and apt usable.
  zstyle ':completion::complete:*' use-cache on
  zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache"

  # Disable case sensitivity
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  unsetopt CASE_GLOB

  # Group matches and describe.
  zstyle ':completion:*:*:*:*:*' menu select
  zstyle ':completion:*:matches' group 'yes'
  zstyle ':completion:*:options' description 'yes'
  zstyle ':completion:*:options' auto-description '%d'
  zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
  zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
  zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
  zstyle ':completion:*:default' list-prompt '%S%M matches%s'
  zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*' group-name ''
  zstyle ':completion:*' verbose yes

  # Don't show already completed options in the list
  zstyle ':completion:*:*:*:*:*' ignore-line 'yes'

  # Fuzzy match mistyped completions.
  zstyle ':completion:*' completer _complete _match _approximate
  zstyle ':completion:*:match:*' original only
  zstyle ':completion:*:approximate:*' max-errors 1 numeric

  # Increase the number of errors based on the length of the typed word.
  zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

  # Don't complete unavailable commands.
  zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

  # Array completion element sorting.
  zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

  # Directories
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
  zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
  zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
  zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
  zstyle ':completion:*' squeeze-slashes true

  # History
  zstyle ':completion:*:history-words' stop yes
  zstyle ':completion:*:history-words' remove-all-dups yes
  zstyle ':completion:*:history-words' list false
  zstyle ':completion:*:history-words' menu yes

  # Environmental Variables
  zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

  # Populate hostname completion.
  zstyle -e ':completion:*:hosts' hosts 'reply=(
    ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
    ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
    ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
  )'

  # Don't complete uninteresting users...
  zstyle ':completion:*:*:*:users' ignored-patterns \
    adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
    dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
    hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
    mailman mailnull mldonkey mysql nagios \
    named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
    operator pcap postfix postgres privoxy pulse pvm quagga radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

  # ... unless we really want to.
  zstyle '*' single-ignored show

  # Ignore multiple entries.
  zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
  zstyle ':completion:*:rm:*' file-patterns '*:all-files'

  # Kill
  zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
  zstyle ':completion:*:*:kill:*' menu yes select
  zstyle ':completion:*:*:kill:*' force-list always
  zstyle ':completion:*:*:kill:*' insert-ids single

  # Man
  zstyle ':completion:*:manuals' separate-sections true
  zstyle ':completion:*:manuals.(^1*)' insert-sections true

  # Media Players
  zstyle ':completion:*:*:mpg123:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
  zstyle ':completion:*:*:mpg321:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
  zstyle ':completion:*:*:ogg123:*' file-patterns '*.(ogg|OGG|flac):ogg\ files *(-/):directories'
  zstyle ':completion:*:*:mocp:*' file-patterns '*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg\ files *(-/):directories'

  # Mutt
  if [[ -s "$HOME/.mutt/aliases" ]]; then
    zstyle ':completion:*:*:mutt:*' menu yes select
    zstyle ':completion:*:mutt:*' users ${${${(f)"$(<"$HOME/.mutt/aliases")"}#alias[[:space:]]}%%[[:space:]]*}
  fi

  # SSH/SCP/RSYNC
  zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
  zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
  zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
  zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
  zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
  zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
  zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
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

  setopt BANG_HIST                 # Treat the '!' character specially during expansion.
  setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
  setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
  setopt SHARE_HISTORY             # Share history between all sessions.
  setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
  setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
  setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
  setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
  setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
  setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
  setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
  setopt HIST_BEEP                 # Beep when accessing non-existent history.

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

    zle -N history-substring-search-up
    zle -N history-substring-search-down

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
      bindkey -M emacs "$key_info[Control]P" history-substring-search-up
      bindkey -M emacs "$key_info[Control]N" history-substring-search-down

      # Vi
      bindkey -M vicmd "k" history-substring-search-up
      bindkey -M vicmd "j" history-substring-search-down

      # Emacs and Vi
      for keymap in 'emacs' 'viins'; do
        bindkey -M "$keymap" "$key_info[Up]" history-substring-search-up
        bindkey -M "$keymap" "$key_info[Down]" history-substring-search-down
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
  setopt BEEP

  #
  # Variables
  #

  # Treat these characters as part of a word.
  WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

  # Use human-friendly identifiers.
  zmodload zsh/terminfo
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
    'Up'           "$terminfo[kcuu1]"
    'Left'         "$terminfo[kcub1]"
    'Down'         "$terminfo[kcud1]"
    'Right'        "$terminfo[kcuf1]"
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
  autoload -Uz edit-command-line
  zle -N edit-command-line

  #
  # Functions
  #

  # Exposes information about the Zsh Line Editor via the $editor_info associative
  # array.
  function editor-info {
    zle reset-prompt
    zle -R
  }
  zle -N editor-info

  # Updates editor information when the keymap changes.
  function zle-keymap-select {
    zle editor-info
  }
  zle -N zle-keymap-select

  # Enables terminal application mode and updates editor information.
  function zle-line-init {
    # The terminal must be in application mode when ZLE is active for $terminfo
    # values to be valid.
    if (( $+terminfo[smkx] )); then
      # Enable terminal application mode.
      echoti smkx
    fi

    # Update editor information.
    zle editor-info
  }
  zle -N zle-line-init

  # Disables terminal application mode and updates editor information.
  function zle-line-finish {
    # The terminal must be in application mode when ZLE is active for $terminfo
    # values to be valid.
    if (( $+terminfo[rmkx] )); then
      # Disable terminal application mode.
      echoti rmkx
    fi

    # Update editor information.
    zle editor-info
  }
  zle -N zle-line-finish

  # Toggles emacs overwrite mode and updates editor information.
  function overwrite-mode {
    zle .overwrite-mode
    zle editor-info
  }
  zle -N overwrite-mode

  # Enters vi insert mode and updates editor information.
  function vi-insert {
    zle .vi-insert
    zle editor-info
  }
  zle -N vi-insert

  # Moves to the first non-blank character then enters vi insert mode and updates
  # editor information.
  function vi-insert-bol {
    zle .vi-insert-bol
    zle editor-info
  }
  zle -N vi-insert-bol

  # Enters vi replace mode and updates editor information.
  function vi-replace  {
    zle .vi-replace
    zle editor-info
  }
  zle -N vi-replace

  # Expands .... to ../..
  function expand-dot-to-parent-directory-path {
    if [[ $LBUFFER = *.. ]]; then
      LBUFFER+='/..'
    else
      LBUFFER+='.'
    fi
  }
  zle -N expand-dot-to-parent-directory-path

  # Displays an indicator when completing.
  function expand-or-complete-with-indicator {
    local indicator="→"
    print -Pn "$indicator"
    zle expand-or-complete
    zle redisplay
  }
  zle -N expand-or-complete-with-indicator

  # Inserts 'sudo ' at the beginning of the line.
  function prepend-sudo {
    if [[ "$BUFFER" != su(do|)\ * ]]; then
      BUFFER="sudo $BUFFER"
      (( CURSOR += 5 ))
    fi
  }
  zle -N prepend-sudo

  # Reset to default key bindings.
  bindkey -d

  #
  # Emacs Key Bindings
  #

  for key in "$key_info[Escape]"{B,b} "${(s: :)key_info[ControlLeft]}"
    bindkey -M emacs "$key" emacs-backward-word
  for key in "$key_info[Escape]"{F,f} "${(s: :)key_info[ControlRight]}"
    bindkey -M emacs "$key" emacs-forward-word

  # Kill to the beginning of the line.
  for key in "$key_info[Escape]"{K,k}
    bindkey -M emacs "$key" backward-kill-line

  # Redo.
  bindkey -M emacs "$key_info[Escape]_" redo

  # Search previous character.
  bindkey -M emacs "$key_info[Control]X$key_info[Control]B" vi-find-prev-char

  # Match bracket.
  bindkey -M emacs "$key_info[Control]X$key_info[Control]]" vi-match-bracket

  # Edit command in an external editor.
  bindkey -M emacs "$key_info[Control]X$key_info[Control]E" edit-command-line

  if (( $+widgets[history-incremental-pattern-search-backward] )); then
    bindkey -M emacs "$key_info[Control]R" \
      history-incremental-pattern-search-backward
    bindkey -M emacs "$key_info[Control]S" \
      history-incremental-pattern-search-forward
  fi

  #
  # Vi Key Bindings
  #

  # Edit command in an external editor.
  bindkey -M vicmd "v" edit-command-line

  # Undo/Redo
  bindkey -M vicmd "u" undo
  bindkey -M vicmd "$key_info[Control]R" redo

  if (( $+widgets[history-incremental-pattern-search-backward] )); then
    bindkey -M vicmd "?" history-incremental-pattern-search-backward
    bindkey -M vicmd "/" history-incremental-pattern-search-forward
  else
    bindkey -M vicmd "?" history-incremental-search-backward
    bindkey -M vicmd "/" history-incremental-search-forward
  fi

  #
  # Emacs and Vi Key Bindings
  #

  for keymap in 'emacs' 'viins'; do
    bindkey -M "$keymap" "$key_info[Home]" beginning-of-line
    bindkey -M "$keymap" "$key_info[End]" end-of-line

    bindkey -M "$keymap" "$key_info[Insert]" overwrite-mode
    bindkey -M "$keymap" "$key_info[Delete]" delete-char
    bindkey -M "$keymap" "$key_info[Backspace]" backward-delete-char

    bindkey -M "$keymap" "$key_info[Left]" backward-char
    bindkey -M "$keymap" "$key_info[Right]" forward-char

    # Expand history on space.
    bindkey -M "$keymap" ' ' magic-space

    # Clear screen.
    bindkey -M "$keymap" "$key_info[Control]L" clear-screen

    # Expand command name to full path.
    for key in "$key_info[Escape]"{E,e}
      bindkey -M "$keymap" "$key" expand-cmd-path

    # Duplicate the previous word.
    for key in "$key_info[Escape]"{M,m}
      bindkey -M "$keymap" "$key" copy-prev-shell-word

    # Use a more flexible push-line.
    for key in "$key_info[Control]Q" "$key_info[Escape]"{q,Q}
      bindkey -M "$keymap" "$key" push-line-or-edit

    # Bind Shift + Tab to go to the previous menu item.
    bindkey -M "$keymap" "$key_info[BackTab]" reverse-menu-complete

    # Complete in the middle of word.
    bindkey -M "$keymap" "$key_info[Control]I" expand-or-complete

    # Expand .... to ../..
    bindkey -M "$keymap" "." expand-dot-to-parent-directory-path

    # Display an indicator when completing.
    bindkey -M "$keymap" "$key_info[Control]I" \
      expand-or-complete-with-indicator

    # Insert 'sudo ' at the beginning of the line.
    bindkey -M "$keymap" "$key_info[Control]X$key_info[Control]S" prepend-sudo
  done

  unset key{,map,bindings}
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
          echo $out
        fi
      } &!
      pids+=$!
    done

    for pid in $pids; do
      while kill -0 $pid >/dev/null 2>&1; do
      done
    done
  else
    for command in $commands; do
      out=$(${=command})
      if [[ $? -eq 0 ]]; then
        echo $out
      fi
    done
  fi
}

###
# Source init scripts for installed packages
###
function _zulu_load_packages() {
  # Source files in the init directory
  setopt EXTENDED_GLOB
  for f in ${base}/init/**/*^(*.zwc)(#q@N); do
    if [[ -L $f ]]; then
      source $(readlink $f)
    else
      source $f
    fi
  done
}

###
# Set up the zulu environment
###
function _zulu_init() {
  local base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  local config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  local help check_for_update no_compile

  # Parse CLI options
  zparseopts -D \
    h=help -help=help \
    c=check_for_update -check-for-update=check_for_update \
    n=no_compile -no-compile=no_compile \
    -dev=dev

  if [[ -n $help ]]; then
    _zulu_init_usage
    return
  fi

  if [[ -n $dev ]]; then
    export ZULU_DEV_MODE=1
  else
    export ZULU_DEV_MODE=0
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
    autoload -U promptinit && promptinit
    local theme=$(cat "$config/theme")
    prompt $theme
  fi

  if [[ -z $no_compile ]]; then
    {
      zulu compile
    } >/dev/null 2>&1 &!
  fi

  [[ -n $check_for_update ]] && _zulu_check_for_update

  return
}
