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

# Detect Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    OS=$(uname -s)
fi

# Install dependencies based on distribution
echo -e "${YELLOW}Installing dependencies for $OS...${RESET}"

case $OS in
    "Ubuntu" | "Debian GNU/Linux")
        sudo apt-get update
        sudo apt-get install -y g++ make libreadline-dev liblua5.3-dev
        ;;
    "GhostFreakOS")
        sudo apt-get update
        sudo apt-get install -y g++ make libreadline-dev liblua5.3-dev
        echo -e "${GREEN}GhostFreakOS detected! Installing dependencies...${RESET}"
        ;;
    "Arch Linux" | "Manjaro Linux")
        sudo pacman -S --noconfirm gcc make readline lua53
        ;;
    "Fedora")
        sudo dnf install -y gcc-c++ make readline-devel lua-devel
        ;;
    "openSUSE Tumbleweed" | "openSUSE Leap")
        sudo zypper install -y gcc-c++ make readline-devel lua53-devel
        ;;
    "Void Linux")
        sudo xbps-install -y gcc make readline-devel lua53-devel
        ;;
    *)
        echo -e "${RED}Unsupported distribution: $OS${RESET}"
        echo -e "${YELLOW}Please install the following packages manually:${RESET}"
        echo "- g++ or gcc-c++"
        echo "- make"
        echo "- readline development files"
        echo "- Lua 5.3 development files"
        exit 1
        ;;
esac

# Create necessary directories
mkdir -p ~/.zencr/plugins ~/.zencr

# Copy default configuration if it doesn't exist
if [ ! -f ~/.zencr/config.lua ]; then
    echo -e "${GREEN}Creating default configuration...${RESET}"
    cp config.lua ~/.zencr/config.lua
fi

# Create build directory
mkdir -p build
cd build

# Configure and build the project
cmake ..
make

# Install the project
sudo make install

# Return to the original directory
cd ..

# Move the binary to /bin
echo -e "${GREEN}Installing Zen Shell binary...${RESET}"
if sudo mv build/zenshell /bin/zen &>/dev/null; then
    sudo chmod +x /bin/zen
    echo -e "${GREEN}Zen Shell installed successfully! Run 'zen' to start.${RESET}"
else
    echo -e "${RED}Failed to move Zen Shell binary to /bin. Please check your permissions.${RESET}"
fi
