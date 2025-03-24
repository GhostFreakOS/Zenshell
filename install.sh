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

set +e # Disable exit on error

# Install dependencies
deps=("g++" "make" "libreadline-dev" "readline-devel" "readline" "libdl" "liblua5.4-dev")
for dep in "${deps[@]}"; do
    if ! dpkg -s $dep &>/dev/null && ! command -v $dep &>/dev/null; then
        echo -e "${YELLOW}Installing dependency: $dep${RESET}"
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
echo -e "${GREEN}Compiling Zen Shell...${RESET}"
if ! g++ -o zen zen.cpp -lreadline -ldl -llua &>/dev/null; then
    echo -e "${RED}Compilation failed. Please check your environment and dependencies.${RESET}"
    exit 1
fi

# Move the binary to /bin
echo -e "${GREEN}Installing Zen Shell binary...${RESET}"
if sudo mv zen /bin/zen &>/dev/null; then
    sudo chmod +x /bin/zen
    echo -e "${GREEN}Zen Shell installed successfully! Run 'zen' to start.${RESET}"
else
    echo -e "${RED}Failed to move Zen Shell binary to /bin. Please check your permissions.${RESET}"
fi
