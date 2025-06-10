#!/bin/bash

# ANSI color codes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# ASCII Art
zen_ascii="
${RED}███████╗███████╗███╗   ██╗
╚══███╔╝██╔════╝████╗  ██║
  ███╔╝ █████╗  ██╔██╗ ██║
 ███╔╝  ██╔══╝  ██║╚██╗██║
███████╗███████╗██║ ╚████║
╚══════╝╚══════╝╚═╝  ╚═══╝${RESET}
"

echo -e "$zen_ascii"
echo -e "${GREEN}Installing Zen Shell...${RESET}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${RESET}"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install package
install_package() {
    if ! dpkg -l | grep -q "^ii  $1"; then
        echo -e "${YELLOW}Installing $1...${RESET}"
        apt-get install -y "$1" >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to install $1${RESET}"
            exit 1
        fi
    fi
}

# Update package list
echo -e "${GREEN}Updating package lists...${RESET}"
apt-get update >/dev/null 2>&1

# Install required dependencies
echo -e "${GREEN}Installing dependencies...${RESET}"
DEPS=(
    "build-essential"
    "cmake"
    "libreadline-dev"
    "liblua5.1-0-dev"
    "pkg-config"
    "git"
)

for dep in "${DEPS[@]}"; do
    install_package "$dep"
done

# Create build directory
echo -e "${GREEN}Creating build directory...${RESET}"
mkdir -p build
cd build

# Configure with CMake
echo -e "${GREEN}Configuring with CMake...${RESET}"
cmake .. || {
    echo -e "${RED}CMake configuration failed${RESET}"
    exit 1
}

# Build
echo -e "${GREEN}Building Zen Shell...${RESET}"
make -j$(nproc) || {
    echo -e "${RED}Build failed${RESET}"
    exit 1
}

# Install
echo -e "${GREEN}Installing Zen Shell...${RESET}"
make install || {
    echo -e "${RED}Installation failed${RESET}"
    exit 1
}

# Create config directory structure
echo -e "${GREEN}Setting up configuration...${RESET}"
CONFIG_DIR="/etc/zencr"
mkdir -p "$CONFIG_DIR/plugins"

# Copy default configuration if it doesn't exist
if [ ! -f "$CONFIG_DIR/config.lua" ]; then
    cp ../config.lua "$CONFIG_DIR/"
fi

# Copy plugins
cp -r ../plugins/* "$CONFIG_DIR/plugins/"

# Set permissions
chown -R root:root "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

# Create user config directory
for USER_HOME in /home/*; do
    if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        USER_CONFIG_DIR="$USER_HOME/.zencr"
        
        # Create user config directory if it doesn't exist
        mkdir -p "$USER_CONFIG_DIR/plugins"
        
        # Copy config file if it doesn't exist
        if [ ! -f "$USER_CONFIG_DIR/config.lua" ]; then
            cp "$CONFIG_DIR/config.lua" "$USER_CONFIG_DIR/"
        fi
        
        # Set ownership
        chown -R "$USER:$USER" "$USER_CONFIG_DIR"
    fi
done

echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${YELLOW}You can now run 'zenshell' to start the shell${RESET}"
echo -e "${YELLOW}Configuration files are located in ~/.zencr/${RESET}"
echo -e "${YELLOW}System-wide configuration is in /etc/zencr/${RESET}"

# Cleanup
cd ..
rm -rf build

exit 0