# Zulu

[![Join the chat at https://gitter.im/zulu-zsh/zulu](https://badges.gitter.im/zulu-zsh/zulu.svg)](https://gitter.im/zulu-zsh/zulu?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Join the slack community at https://zulu-zsh.slack.com](https://zulu-slack.herokuapp.com/badge.svg)](https://zulu-slack.herokuapp.com)

Zulu is a total environment manager for ZSH.

## Features

* No need to modify config files or reload ZSH when installing packages, creating aliases or modifying your `$PATH`.
* Any git repository can be a package, check out [the index](//github.com/zulu-zsh/index) and [contribute](//github.com/zulu-zsh/zulu/blob/master/CONTRIBUTING.md).

## Requirements

* ZSH `5.0.2` or above
* git `1.9.1` or above

## Installation

### One-liner

Zulu comes with its own install script, which is the recommended method of install.

```sh
curl -L https://git.io/zulu-install | zsh && zsh
```

### For the cautious

```sh
git clone https://github.com/zulu-zsh/install zulu-install
chmod u+x zulu-install/install
. ./zulu-install/install
```

### Manual Installation

Sure you don't want to use that install script? Ok then, here we go.

```sh
# Edit these as needed. Make sure to add them to your .zshrc if you change them
ZULU_DIR=~/.zulu
ZULU_CONFIG_DIR=~/.config/zulu

# Create directories needed for packages
mkdir -p ${ZULU_DIR}/{bin,share,init,packages}
touch ${ZULU_DIR}/{bin,share,init,packages}/.gitkeep

# Create config directory
mkdir -p "${ZULU_CONFIG_DIR}/functions"

# Clone the core and index repositories
git clone https://github.com/zulu-zsh/zulu ${ZULU_DIR}/core
git clone https://github.com/zulu-zsh/index ${ZULU_DIR}/index

# Store contents of $path
pathfile="${ZULU_CONFIG_DIR}/path"
echo "${ZULU_DIR}/bin" > $pathfile
for p in "${path[@]}"; do
  echo "$p" >> $pathfile
done

# Store contents of $fpath
pathfile="${ZULU_CONFIG_DIR}/fpath"
echo "${ZULU_DIR}/share" > $pathfile
for p in "${fpath[@]}"; do
  echo "$p" >> $pathfile
done

# Store contents of $cdpath
pathfile="${ZULU_CONFIG_DIR}/cdpath"
echo "" > $pathfile
for p in "${cdpath[@]}"; do
  echo "$p" >> $pathfile
done

# Store aliases
local aliasfile="${ZULU_CONFIG_DIR}/alias"
echo "" > $aliasfile
IFS=$'\n'; for a in `alias`; do
  echo "alias $a\n" >> $aliasfile
done

# Install the completion for zulu commands
ln -s ${ZULU_DIR}/core/zulu.zsh-completion ${ZULU_DIR}/share/_zulu

# Install the initialisation script to run on startup
echo "# Initialise zulu plugin manager" >> ${ZDOTDIR:-$HOME}/.zshrc
echo 'source "${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}/core/zulu"' >> ${ZDOTDIR:-$HOME}/.zshrc
echo "zulu init" >> ${ZULU_DIR:-$HOME}/.zshrc

# Hooray! Zulu is installed. Load it now
source ${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}/core/zulu
zulu init
```

## Usage

### Managing packages

Packages are found in the [index](//github.com/zulu-zsh/index). Each package defines its own list of executables (which are symlinked into `$PATH`), shared files (which are symlinked to `$fpath`) and files which should be loaded during environment initialisation. Unlike other package managers, zulu handles everything for you, so things should work as soon as the package finishes installing.

```sh
# Install a package
zulu install autosuggestions

# Disable a package
zulu unlink autosuggestions

# Link (enable) a package
zulu link autosuggestions

# Uninstall a package
zulu uninstall autosuggestions

# List installed packages
zulu list

# List all available packages
zulu list --all

# Search for packages
zulu search suggest

# Get more info for a package
zulu info autosuggestions
```

Zulu intelligently autocompletes package names for you when using any of the above commands

### Managing `$path`, `$fpath` and `$cdpath`

Zulu can manage the list of directories in `$path`, `$fpath` and `$cdpath` for you, negating the need for modifying init files and reloading the environment.

Path commands support both absolute and relative paths.

```sh
# Add a directory to $path
zulu path add /path/to/dir

# Add current durectory to $cdpath
zulu cdpath add .

# Remove a directory from $fpath
zulu fpath rm /path/to/dir

# List all directories in $path
zulu path
```

### Managing aliases

Zulu can also manage your aliases. Using the `zulu alias` commands will add or
remove the alias, loading it into your existing session and ensuring it is
sourced at the next initialisation in a single command.

```sh
# Add an alias
zulu alias add l 'k -ha'

# Remove an alias
zulu alias rm l

# List aliases
zulu alias
```

### Managing environment variables

Zulu can also manage your environment variables. Using the `zulu var` commands will add or remove the variable, loading it into your existing session and ensuring it is sourced at the next initialisation in a single command.

```sh
# Add an environment variable
zulu var add MY_AWESOME_VAR 'unicorns'

# Remove an environment variable
zulu var rm MY_AWESOME_VAR

# List environment variables
zulu var
```

### Managing functions

Zulu can manage user functions. Using the `zulu func` commands will allow you to
add new functions, creating some boilerplate and opening the resulting file in
your `$EDITOR` for you to add the function body. When you save, the function is
immediately sourced, and will be sourced in every future session automatically.

```sh
# Add a function
zulu func add myawesomefunction

# Edit a function
zulu func edit myawesomefunction

# Remove a function
zulu func rm myawesomefunction

# List functions
zulu func
```

### Choosing a theme

Zulu can switch themes for you, and will load the chosen theme on next login.

```sh
# Install and select a theme
zulu install filthy

# Select an installed theme
zulu theme filthy
```

### Updating Zulu

```sh
# Update zulu's core
zulu self-update

# Update the package index
zulu update

# Check if updates are available
zulu update --check
zulu self-update --check
```

## Uninstalling

Tried zulu and it's not for you? We won't hold it against you. Here's how you can remove it:

```sh
rm -rf "${ZULU_DIR:-"${ZDOTDIR:-$HOME}/.zulu"}"
rm -rf "${ZULU_CONFIG_DIR:-"${ZDOTDIR:-$HOME}/.config/zulu"}"
```

Then just remove the initialisation lines from your `.zshrc` and zulu has been uninstalled.

## Contributing

All contributions are welcome, and encouraged. Please read our [contribution guidelines](CONTRIBUTING.md) and [code of conduct](CODE-OF-CONDUCT.md) for more information.

## License

Copyright (c) 2016 James Dinsdale <hi@molovo.co> (molovo.co)

Zulu is licensed under The MIT License (MIT)

Icon is [Shield](https://thenounproject.com/search/?q=zulu&i=163736) by Ivan Colic from The Noun Project

## Team

* [James Dinsdale](http://molovo.co)
