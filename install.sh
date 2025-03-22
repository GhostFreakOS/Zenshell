#!/bin/bash

# Zen Shell Installer
echo -e "\033[1;32mInstalling Zen Shell...\033[0m"

# Detect package manager
if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt update && sudo apt install -y"
    REQUIRED_PKGS=("gcc" "make" "libreadline-dev" "libc6-dev")
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -Sy --needed"
    REQUIRED_PKGS=("gcc" "make" "readline" "glibc")
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    REQUIRED_PKGS=("gcc" "make" "readline-devel" "glibc-devel")
elif command -v xbps-install &>/dev/null; then
    PKG_MANAGER="xbps"
    INSTALL_CMD="sudo xbps-install -Sy"
    REQUIRED_PKGS=("gcc" "make" "readline-devel" "glibc-devel")
elif command -v zypper &>/dev/null; then
    PKG_MANAGER="zypper"
    INSTALL_CMD="sudo zypper install -y"
    REQUIRED_PKGS=("gcc" "make" "readline-devel" "glibc-devel")
else
    echo -e "\033[1;31mUnsupported package manager. Install dependencies manually.\033[0m"
    exit 1
fi

# Check and install missing packages
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" &>/dev/null && ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo -e "\033[1;33mMissing dependencies detected: ${MISSING_PKGS[*]}\033[0m"
    echo "Installing required packages..."
    $INSTALL_CMD "${MISSING_PKGS[@]}"
fi

# Compile Zen Shell
echo -e "\033[1;34mCompiling Zen Shell...\033[0m"
gcc -o zen zen.c -lreadline -ldl

# Move Zen Shell to /bin for global access
echo -e "\033[1;34mInstalling Zen Shell to /bin...\033[0m"
sudo mv zen /bin/zen
sudo chmod +x /bin/zen

# Create ~/.zencr directory for plugins and configs
echo -e "\033[1;34mSetting up Zen configuration...\033[0m"
mkdir -p ~/.zencr/plugins
touch ~/.zencr/zenrc

echo -e "\033[1;32mInstallation Complete! Type 'zen' to start Zen Shell.\033[0m"
