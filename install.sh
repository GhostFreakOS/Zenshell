#!/bin/bash

echo "Installing Zen Shell..."

set +e # Disable exit on error

# Install dependencies
deps=("g++" "make" "libreadline-dev" "readline-devel" "readline" "libdl" "liblua5.4-dev")
for dep in "${deps[@]}"; do
    if ! dpkg -s $dep &>/dev/null && ! command -v $dep &>/dev/null; then
        echo "Installing dependency: $dep"
        sudo apt-get update -y &>/dev/null
        sudo apt-get install -y $dep &>/dev/null || \
        sudo pacman -S --noconfirm $dep &>/dev/null || \
        sudo dnf install -y $dep &>/dev/null || \
        sudo xbps-install -y $dep &>/dev/null || \
        sudo zypper install -y $dep &>/dev/null || \
        sudo homebrew install $dep &>/dev/null || \
        sudo pkg install -y $dep &>/dev/null
    fi
done

set -e # Re-enable exit on error

# Create necessary directories
mkdir -p ~/.zencr/plugins ~/.zencr/config

# Compile Zen Shell
echo "Compiling Zen Shell..."
if ! g++ -o zen zen.cpp -lreadline -ldl -llua &>/dev/null; then
    echo "Compilation failed. Please check your environment and dependencies."
    exit 1
fi

# Move the binary to /bin
echo "Installing Zen Shell binary..."
if sudo mv zen /bin/zen &>/dev/null; then
    sudo chmod +x /bin/zen
    echo "Zen Shell installed successfully! Run 'zen' to start."
else
    echo "Failed to move Zen Shell binary to /bin. Please check your permissions."
fi
