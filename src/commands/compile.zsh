#!/usr/bin/env zsh

###
# Output usage information and exit
###
function _zulu_compile_usage() {
  builtin echo '\033[0;32mUsage:\033[0;m'
  builtin echo '  zulu_compile [options]'
}

###
# Resolve symbolic links to a file, a compare it's last-modified date
# with the compiled version, recompiling if needed
###
function _zulu_compile_if_needed() {
  local file="$1" follow_symlinks

  builtin zparseopts -D \
    f=follow_symlinks -follow-symlinks=follow_symlinks

  # We can't compile files that do not exist
  [[ ! -e $file ]] && return

  # Resolve symlinks if necessary
  [[ -n $follow_symlinks && -L $file ]] && file=$(command readlink $file)

  # Check if the file is newer than it's compiled version,
  # and recompile if necessary
  if [[ -s ${file} && ( ! -s ${file}.zwc || ${file} -nt ${file}.zwc) ]]; then
    zcompile ${file}
  fi
}

###
# The main zulu_compile process
###
(( $+functions[_zulu_compile] )) || function _zulu_compile() {
  local base=${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}
  local config=${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}
  local help version

  builtin zparseopts -D \
    h=help -help=help

  if [[ -n $help ]]; then
    _zulu_compile_usage
    exit
  fi

  setopt EXTENDED_GLOB
  # A list of glob paths pointing to files to be compiled
  local -a compile_targets; compile_targets=(
    # Zulu's core
    ${base}/core/zulu

    # Files linked by packages
    ${base}/share/**/*^(*.zwc)(#q@)
    ${base}/bin/**/*^(*.zwc)(#q@)

    # Completion dump
    ${ZDOTDIR:-${HOME}}/.zcomp^(*.zwc)(.)

    # User env files
    ${ZDOTDIR:-${HOME}}/.zshenv
    ${ZDOTDIR:-${HOME}}/.zlogin
    ${ZDOTDIR:-${HOME}}/.zprofile
    ${ZDOTDIR:-${HOME}}/.zshrc
    ${ZDOTDIR:-${HOME}}/.zlogout
  )

  # A second list of compile targets. These files have their symlinks resolved
  # before they are sourced, so we need to follow the symlink before compiling,
  # to ensure the compiled version is picked up
  local -a linked_compile_targets; linked_compile_targets=(
    # Initialisation scripts for packages
    ${base}/init/**/*^(*.zwc)(#q@)
  )

  # Loop through each of the files marked for compilation, and compile
  # them if necessary
  for file in ${(@f)compile_targets}; do
    _zulu_compile_if_needed $file
  done

  # Loop through each of the files marked for compilation, follow their
  # symlinks, and compile them if necessary
  for file in ${(@f)linked_compile_targets}; do
    _zulu_compile_if_needed --follow-symlinks $file
  done
}
