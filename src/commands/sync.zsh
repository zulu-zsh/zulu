###
# Output usage information
###
function _zulu_sync_usage() {
  echo $(_zulu_color yellow 'Usage:')
  echo '  zulu sync'
  echo
  echo $(_zulu_color yellow 'Commands:')
  echo '  pull      Pull changes from remote repository'
  echo '  push      Push local changes to remote repository'
}

###
# Pull changes from the remote repository
###
function _zulu_sync_pull_changes() {
  local oldPWD=$PWD
  cd $config_dir

  # Start the progress spinner
  _zulu_revolver start 'Syncing...'

  # Fetch from the remote
  git fetch origin >/dev/null 2>&1

  # Check if any updates are available
  count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
  down="$count[(w)2]"

  # If no updates are available, stop and tell the user
  if [[ $down -eq 0 ]]; then
    cd $oldPWD
    unset oldPWD

    _zulu_revolver stop
    echo $(_zulu_color green 'No updates found')
    return
  fi

  # Rebase master over the updates
  git rebase -p --autostash origin/master >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    cd $oldPWD
    unset oldPWD

    _zulu_revolver stop
    echo $(_zulu_color red 'Failed to merge changes from remote')
    return 1
  fi

  zulu bundle
  zulu init

  # Success! Tell the user
  _zulu_revolver stop
  echo "$(_zulu_color green '✔') Remote changes synced"

  cd $oldPWD
  unset oldPWD
}

function _zulu_sync_push_changes() {
  local oldPWD=$PWD
  cd $config_dir

  # Start the progress spinner
  _zulu_revolver start 'Syncing...'

  # Fetch from the remote
  git fetch origin >/dev/null 2>&1

  # Check if any updates are available
  count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
  down="$count[(w)2]"

  # If no updates are available, stop and tell the user
  if [[ $down -gt 0 ]]; then
    cd $oldPWD
    unset oldPWD

    _zulu_revolver stop
    echo $(_zulu_color red 'Remote has been updated. Pull changes first')
    return 1
  fi

  dirty="$(git diff --ignore-submodules=all HEAD 2>/dev/null)"
  if [[ -z $dirty ]]; then
    cd $oldPWD
    unset oldPWD

    _zulu_revolver stop
    echo $(_zulu_color green 'Nothing to sync')
    return 1
  fi

  git add . >/dev/null 2>&1
  git commit -m "Sync config from $HOST" >/dev/null 2>&1
  git push -u origin master >/dev/null 2>&1

  _zulu_revolver stop
  echo "$(_zulu_color green '✔') Local changes uploaded"

  cd $oldPWD
  unset oldPWD
}

###
# Check if the sync repository has already been set up
###
function _zulu_sync_repository_exists() {
  local oldPWD=$PWD
  cd $config_dir

  # Check if the config directory is already within a git repository
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    # If it is, check if the config directory is the git root.
    # If it's not, we'll exit, since syncing is probably already
    # being handled outside of Zulu
    git_dir=$(git rev-parse --git-dir)
    if [[ $git_dir = ".git" ]]; then
      cd $oldPWD
      unset oldPWD

      return 0
    fi
  fi

  cd $oldPWD
  unset oldPWD

  return 1
}

###
# Setup a new environment ready for syncing
###
function _zulu_sync_setup() {
  # Change into the config directory
  local oldPWD=$PWD
  cd $config_dir

  # Check if the config directory is already within a git repository
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    # If it is, check if the config directory is the git root.
    # If it's not, we'll exit, since syncing is probably already
    # being handled outside of Zulu
    git_dir=$(git rev-parse --git-dir)
    if [[ $git_dir != ".git" ]]; then
      cd $oldPWD
      unset oldPWD

      echo $(_zulu_color red "It looks like $config_dir is already within a git repository at $git_dir")
      return 1
    fi

    return
  fi

  # Create a new git repository in the config directory
  if ! git init >/dev/null 2>&1; then
    cd $oldPWD
    unset oldPWD

    echo $(_zulu_color red 'Failed to initialise empty repository')
    exit 1
  fi

  # Ask the user for the remote repository URL
  echo $(_zulu_color yellow 'Sync has not been set up yet')
  echo 'If you haven'\''t already, create a repository using'
  echo 'a remote service such as github.com'
  echo
  vared -p "$(_zulu_color yellow 'Please enter your repository URL: ')" -c repo_url

  # If a URL was not provided, exit
  if [[ -z $repo_url ]]; then
    cd $oldPWD
    unset oldPWD

    echo $(_zulu_color red 'Repository URL not provided')
    return 1
  fi

  # Set the repository's origin to the remote
  git remote add origin $repo_url
  git fetch origin >/dev/null 2>&1

  # Create a .gitignore if one does not exist, to ensure
  # private configuration is not synced
  if [[ ! -f .gitignore ]]; then
    echo ".backup
*.private" > .gitignore
  fi

  remotes=$(git rev-parse --remotes)
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
      p|P )
        _zulu_revolver start 'Overwriting remote config...'
        # Commit changes
        git add . >/dev/null 2>&1
        git commit -m "Sync config from $HOST" >/dev/null 2>&1

        # Force push to overwrite remote config
        git push --force --set-upstream origin master >/dev/null 2>&1

        _zulu_revolver stop
        echo
        echo "$(_zulu_color green '✔') Sync setup complete"

        # Return to the previous directory
        cd $oldPWD
        unset oldPWD
        ;;

      # Back up the existing config to $ZULU_CONFIG_DIR/.backup
      # and create a fresh clone of the remote repository in $ZULU_CONFIG_DIR
      b|B )
        _zulu_revolver start 'Backing up and downloading from remote...'

        # Return to the previous directory so we can move
        # the current directory
        cd $oldPWD
        unset oldPWD

        # Move existing config directory into tmp
        mv "$ZULU_CONFIG_DIR" "/tmp/zulu-config.bkp"

        # Since we have no local branch we can't pull
        # a remote branch into the local repository,
        # so we create a fresh clone instead
        git clone $repo_url $ZULU_CONFIG_DIR >/dev/null 2>&1

        # Move the temporary backup back into the repository
        # so that it's easy to find. It will be ignored by git
        mv "/tmp/zulu-config.bkp" "$ZULU_CONFIG_DIR/.backup"

        _zulu_revolver stop
        echo
        echo "$(_zulu_color green '✔') Sync setup complete"
        echo "Old config backed up to $ZULU_CONFIG_DIR/.backup"
        echo

        zulu bundle
        zulu init

        echo "$(_zulu_color green '✔') Remote changes synced"
        ;;

      # Something else was entered, exit
      * )
        # Return to the previous directory
        cd $oldPWD
        unset oldPWD

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
  zparseopts -D h=help -help=help

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
      echo $(_zulu_color red "Unrecognized command $ctx")
      return 1
  esac
}
