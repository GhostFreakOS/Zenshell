#!/bin/bash

set -e

echo "Installing Zen Shell..."

# Install dependencies
deps=("g++" "make" "readline-devel" "dlopen" "libdl")
for dep in "${deps[@]}"; do
    if ! command -v $dep &> /dev/null; then
        echo "Installing dependency: $dep"
        sudo apt install -y $dep || sudo pacman -S --noconfirm $dep || sudo dnf install -y $dep || sudo xbps-install -y $dep || sudo zypper install -y $dep
    fi
done

# Create necessary directories
mkdir -p ~/.zencr/plugins
mkdir -p ~/.zencr/themes

# Compile Zen Shell
g++ -o zen zen.cpp -lreadline -ldl

# Move the binary to /bin
sudo mv zen /bin/zen

# Set permissions
sudo chmod +x /bin/zen

echo "Zen Shell installed successfully! Run 'zen' to start."
