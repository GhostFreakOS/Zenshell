#!/bin/bash

# Define variables
ZEN_SHELL_SOURCE="zen.c"
ZEN_SHELL_BINARY="zen"
INSTALL_DIR="/usr/local/bin"

# Check for root permissions
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

# Compile the Zen Shell
gcc -o "$ZEN_SHELL_BINARY" "$ZEN_SHELL_SOURCE" -lreadline -ldl
if [[ $? -ne 0 ]]; then
    echo "Compilation failed. Please check for errors."
    exit 1
fi

# Move the binary to /usr/local/bin
mv "$ZEN_SHELL_BINARY" "$INSTALL_DIR/zen"
chmod +x "$INSTALL_DIR/zen"

# Confirm installation
echo "Zen Shell has been successfully installed!"
echo "You can now run it by typing 'zen' in your terminal."
