###
# Output usage information
###
function _zulu_sync_usage() {
  builtin echo $(_zulu_color yellow 'Usage:')
  builtin echo '  zulu sync'
  builtin echo
  builtin echo $(_zulu_color yellow 'Commands:')
  builtin echo '  pull      Pull changes from remote repository'
  builtin echo '  push      Push local changes to remote repository'
}

###
# Pull changes from the remote repository
###
function _zulu_sync_pull_changes() {
  local oldPWD=$PWD
  builtin cd $config_dir

  # Start the progress spinner
  _zulu_revolver start 'Syncing...'

  # Fetch from the remote
  command git fetch origin >/dev/null 2>&1

  # Check if any updates are available
  count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
  down="$count[(w)2]"

  # If no updates are available, stop and tell the user
  if [[ $down -eq 0 ]]; then
    builtin cd $oldPWD
    builtin unset oldPWD

    _zulu_revolver stop
    builtin echo $(_zulu_color green 'No updates found')
    return
  fi

  # Rebase master over the updates
  command git rebase -p --autostash origin/master >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    builtin cd $oldPWD
    builtin unset oldPWD

    _zulu_revolver stop
    builtin echo $(_zulu_color red 'Failed to merge changes from remote')
    return 1
  fi

  zulu bundle
  zulu init

  # Success! Tell the user
  _zulu_revolver stop
  builtin echo "$(_zulu_color green '✔') Remote changes synced"

  builtin cd $oldPWD
  builtin unset oldPWD
}

function _zulu_sync_push_changes() {
  local oldPWD=$PWD
  builtin cd $config_dir

  # Start the progress spinner
  _zulu_revolver start 'Syncing...'

  # Fetch from the remote
  command git fetch origin >/dev/null 2>&1

  # Check if any updates are available
  count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
  down="$count[(w)2]"

  # If no updates are available, stop and tell the user
  if [[ $down -gt 0 ]]; then
    builtin cd $oldPWD
    builtin unset oldPWD

    _zulu_revolver stop
    builtin echo $(_zulu_color red 'Remote has been updated. Pull changes first')
    return 1
  fi

  dirty="$(command git diff --ignore-submodules=all HEAD 2>/dev/null)"
  if [[ -z $dirty ]]; then
    builtin cd $oldPWD
    builtin unset oldPWD

    _zulu_revolver stop
    builtin echo $(_zulu_color green 'Nothing to sync')
    return 1
  fi

  command git add . >/dev/null 2>&1
  command git commit -m "Sync config from $HOST" >/dev/null 2>&1
  command git push -u origin master >/dev/null 2>&1

  _zulu_revolver stop
  builtin echo "$(_zulu_color green '✔') Local changes uploaded"

  builtin cd $oldPWD
  builtin unset oldPWD
}

###
# Check if the sync repository has already been set up
###
function _zulu_sync_repository_exists() {
  local oldPWD=$PWD
  builtin cd $config_dir

  # Check if the config directory is already within a git repository
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    # If it is, check if the config directory is the git root.
    # If it's not, we'll exit, since syncing is probably already
    # being handled outside of Zulu
    git_dir=$(command git rev-parse --git-dir)
    if [[ $git_dir = ".git" ]]; then
      builtin cd $oldPWD
      builtin unset oldPWD

      return 0
    fi
  fi

  builtin cd $oldPWD
  builtin unset oldPWD

  return 1
}

###
# Setup a new environment ready for syncing
###
function _zulu_sync_setup() {
  # Change into the config directory
  local oldPWD=$PWD
  builtin cd $config_dir

  # Check if the config directory is already within a git repository
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    # If it is, check if the config directory is the git root.
    # If it's not, we'll exit, since syncing is probably already
    # being handled outside of Zulu
    git_dir=$(command git rev-parse --git-dir)
    if [[ $git_dir != ".git" ]]; then
      builtin cd $oldPWD
      builtin unset oldPWD

      builtin echo $(_zulu_color red "It looks like $config_dir is already within a git repository at $git_dir")
      return 1
    fi

    return
  fi

  # Create a new git repository in the config directory
  if ! command git init >/dev/null 2>&1; then
    builtin cd $oldPWD
    builtin unset oldPWD

    builtin echo $(_zulu_color red 'Failed to initialise empty repository')
    exit 1
  fi

  # Ask the user for the remote repository URL
  builtin echo $(_zulu_color yellow 'Sync has not been set up yet')
  builtin echo 'If you haven'\''t already, create a repository using'
  builtin echo 'a remote service such as github.com'
  builtin echo
  vared -p "$(_zulu_color yellow 'Please enter your repository URL: ')" -c repo_url

  # If a URL was not provided, exit
  if [[ -z $repo_url ]]; then
    builtin cd $oldPWD
    builtin unset oldPWD

    builtin echo $(_zulu_color red 'Repository URL not provided')
    return 1
  fi

  # Set the repository's origin to the remote
  command git remote add origin $repo_url
  command git fetch origin >/dev/null 2>&1

  # Create a .gitignore if one does not exist, to ensure
  # private configuration is not synced
  if [[ ! -f .gitignore ]]; then
    builtin echo ".backup
*.private" > .gitignore
  fi

  remotes=$(command git rev-parse --remotes)
  if [[ -n $remotes ]]; then
    # The repository provided already has a HEAD
    # Present the user with some options
    vared -p "
$(_zulu_color yellow "It looks like there's already some code in that repository")
Please choose from one of the following options:

  p) Push local changes, and overwrite the remote
  b) Back up local changes, and pull from remote
  *) Cancel and exit

  Your choice: " -c choice

    case $choice in
      # Force push the empty repository to the remote,
      # overwriting any existing remote config
     ( p|P )
        _zulu_revolver start 'Overwriting remote config...'
        # Commit changes
        command git add . >/dev/null 2>&1
        command git commit -m "Sync config from $HOST" >/dev/null 2>&1

        # Force push to overwrite remote config
        command git push --force --set-upstream origin master >/dev/null 2>&1

        _zulu_revolver stop
        builtin echo
        builtin echo "$(_zulu_color green '✔') Sync setup complete"

        # Return to the previous directory
        builtin cd $oldPWD
        builtin unset oldPWD
        ;;

      # Back up the existing config to $ZULU_CONFIG_DIR/.backup
      # and create a fresh clone of the remote repository in $ZULU_CONFIG_DIR
     ( b|B )
        _zulu_revolver start 'Backing up and downloading from remote...'

        # Return to the previous directory so we can move
        # the current directory
        builtin cd $oldPWD
        builtin unset oldPWD

        # Move existing config directory into tmp
        command mv "$ZULU_CONFIG_DIR" "/tmp/zulu-config.bkp"

        # Since we have no local branch we can't pull
        # a remote branch into the local repository,
        # so we create a fresh clone instead
        command git clone $repo_url $ZULU_CONFIG_DIR >/dev/null 2>&1

        # Move the temporary backup back into the repository
        # so that it's easy to find. It will be ignored by git
        command mv "/tmp/zulu-config.bkp" "$ZULU_CONFIG_DIR/.backup"

        _zulu_revolver stop
        builtin echo
        builtin echo "$(_zulu_color green '✔') Sync setup complete"
        builtin echo "Old config backed up to $ZULU_CONFIG_DIR/.backup"
        builtin echo

        zulu bundle
        zulu init

        builtin echo "$(_zulu_color green '✔') Remote changes synced"
        ;;

      # Something else was entered, exit
     ( * )
        # Return to the previous directory
        builtin cd $oldPWD
        builtin unset oldPWD

        return 1
        ;;
    esac
  fi
}

###
# The main sync command
###
function _zulu_sync() {
  local ctx config_dir

  # Parse options
  builtin zparseopts -D h=help -help=help

  # Output help and return if requested
  if [[ -n $help ]]; then
    _zulu_sync_usage
    return
  fi

  # The path to the config directory
  config_dir="${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}"

  # Check if the repository exists
  if ! _zulu_sync_repository_exists; then
    # It doesn't. Create it
    _zulu_sync_setup
    return $?
  fi

  ctx="$1"

  if [[ -z $ctx ]]; then
    # Sync changes both ways
    _zulu_sync_pull_changes && _zulu_sync_push_changes
    return $?
  fi

  case $ctx in
    push )
      _zulu_sync_push_changes
      ;;
    pull )
      _zulu_sync_pull_changes
      ;;
    * )
      builtin echo $(_zulu_color red "Unrecognized command $ctx")
      return 1
  esac
}
