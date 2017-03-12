#!/usr/bin/env zsh

# Clear the file to start with
cat /dev/null > zulu

# Start with the shebang
echo "#!/usr/bin/env zsh\n" >> zulu

# We need to do some fancy globbing
setopt EXTENDED_GLOB

# Print each of the source files into the target, removing any comments
# from the compiled executable
cat src/**/(^zulu).zsh | grep -v -E '^(\s*#.*[^"])$' >> zulu

# Print the main command last
cat src/zulu.zsh | grep -v -E '^(\s*#.*[^"])$' >> zulu

# Make sure the file is executable
chmod u+x zulu

# Let the user know we're finished
echo "\033[0;32m✔\033[0;m zulu built successfully"
