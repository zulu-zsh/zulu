###
# Get a unique hash which refers to the user
###
function _zulu_analytics_user_key() {
  local -a hash_cmds; hash_cmds=(sha256sum gsha256sum)
  local cmd hash_cmd

  # If a user ID is already set in the config file.
  # we don't need to generate one
  if zulu config user_id >/dev/null 2>&1; then
    builtin echo $(zulu config user_id)
    return
  fi

  # Loop through each of the hashing commands
  for hash_cmd in $hash_cmds; do
    # Check if the command is installed
    if builtin type $hash_cmd >/dev/null 2>&1; then
      # It's installed, we'll set it to be used
      # and break the loop
      cmd=$hash_cmd
      break
    fi
  done

  # A hashing command could not be found, we'll just
  # skip hashing for this user
  if [[ -z $cmd ]]; then
    return
  fi

  # Create a hash from the user's username and hostname
  hash=$(builtin echo -n "$USER@$HOST" | $cmd)

  # Store the hash in the Zulu config file
  # and return it
  zulu config set user_id ${hash:0:$(( ${#hash} - 2 ))}
}

###
# Send the event data to Heap
###
function _zulu_analytics_track() {
  if ! _zulu_analytics_enabled; then
    return
  fi

  local evt="$1" user="$(_zulu_analytics_user_key)"

  # Yes, you could run this command to post data
  # directly to our analytics provider, but please
  # don't. We collect this data to allow us to see
  # which of Zulu's features are most important to
  # you, the user, and find ways to improve Zulu.
  # If the data is inaccurate, it makes supporting
  # Zulu more difficult. Please don't be a dick.
  command curl \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{
      \"app_id\": \"2918660738\",
      \"identity\": \"$user\",
      \"event\": \"$evt\"
    }" 'https://heapanalytics.com/api/track' >/dev/null 2>&1
}

function _zulu_analytics_enabled() {
  if ! zulu config analytics >/dev/null 2>&1; then
    # Turn on by default
    zulu config set analytics true >/dev/null 2>&1

    # Let the user know they can opt-out
    builtin echo 'Zulu collects anonymous usage data to allow the developers to see
which of Zulu'\''s features are most important to you, the user, and to
continue to improve Zulu for you.

If you'\''d like to opt-out of sending this anonymous data, you can do so by
running the following command

    zulu config set analytics false'
  fi

  # If the user has opted out, go no further
  if [[ $(zulu config analytics) != 'true' ]]; then
    return 1
  fi
}
