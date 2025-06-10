#!/bin/bash

# ANSI color codes
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# ASCII Art
echo -e "${RED}
███████╗███████╗███╗   ██╗
╚══███╔╝██╔════╝████╗  ██║
  ███╔╝ █████╗  ██╔██╗ ██║
 ███╔╝  ██╔══╝  ██║╚██╗██║
███████╗███████╗██║ ╚████║
╚══════╝╚══════╝╚═╝  ╚═══╝${RESET}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

# Create log file
LOG_FILE="/tmp/zenshell_install.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

log_info "Starting Zen Shell installation..."

# Check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check disk space (500MB required)
    local free_space=$(df -m . | awk 'NR==2 {print $4}')
    if [ "${free_space}" -lt 500 ]; then
        log_error "Insufficient disk space. Required: 500MB, Available: ${free_space}MB"
        return 1
    fi

    # Check RAM (256MB required)
    local total_ram=$(free -m | awk '/Mem:/ {print $2}')
    if [ "${total_ram}" -lt 256 ]; then
        log_error "Insufficient RAM. Required: 256MB, Available: ${total_ram}MB"
        return 1
    fi

    log_success "System requirements met"
    return 0
}

# Install required packages
install_dependencies() {
    log_info "Updating package lists..."
    apt-get update || {
        log_error "Failed to update package lists"
        return 1
    }

    log_info "Installing dependencies..."
    local DEPS=(
        "build-essential"
        "cmake"
        "libreadline-dev"
        "liblua5.1-0-dev"
        "pkg-config"
        "git"
    )

    for dep in "${DEPS[@]}"; do
        log_info "Installing ${dep}..."
        if ! apt-get install -y "$dep"; then
            log_error "Failed to install ${dep}"
            return 1
        fi
    done

    log_success "All dependencies installed successfully"
    return 0
}

# Build project
build_project() {
    log_info "Creating build directory..."
    mkdir -p build || {
        log_error "Failed to create build directory"
        return 1
    }
    cd build

    log_info "Configuring with CMake..."
    if ! cmake ..; then
        log_error "CMake configuration failed"
        cd ..
        return 1
    fi

    log_info "Building Zen Shell..."
    if ! make -j$(nproc); then
        log_error "Build failed"
        cd ..
        return 1
    fi

    log_success "Build completed successfully"
    cd ..
    return 0
}

# Install the shell
install_shell() {
    log_info "Installing Zen Shell..."
    cd build
    if ! make install; then
        log_error "Installation failed"
        cd ..
        return 1
    fi
    cd ..

    log_success "Installation completed"
    return 0
}

# Setup configuration
setup_configuration() {
    log_info "Setting up configuration..."
    
    # Create system-wide config directory
    local CONFIG_DIR="/etc/zencr"
    local PLUGINS_DIR="${CONFIG_DIR}/plugins"
    
    mkdir -p "${CONFIG_DIR}/plugins" || {
        log_error "Failed to create configuration directories"
        return 1
    }

    # Copy configuration files
    if [ ! -f "${CONFIG_DIR}/config.lua" ]; then
        cp config.lua "${CONFIG_DIR}/" || {
            log_error "Failed to copy config.lua"
            return 1
        }
    fi

    # Copy plugins
    cp -r plugins/* "${CONFIG_DIR}/plugins/" || {
        log_error "Failed to copy plugins"
        return 1
    }

    # Set permissions
    chown -R root:root "${CONFIG_DIR}"
    chmod -R 755 "${CONFIG_DIR}"

    # Setup user configurations
    for USER_HOME in /home/*; do
        if [ -d "${USER_HOME}" ]; then
            USER=$(basename "${USER_HOME}")
            USER_CONFIG_DIR="${USER_HOME}/.zencr"
            
            mkdir -p "${USER_CONFIG_DIR}/plugins"
            cp -n "${CONFIG_DIR}/config.lua" "${USER_CONFIG_DIR}/"
            cp -r "${CONFIG_DIR}/plugins/"* "${USER_CONFIG_DIR}/plugins/"
            chown -R "${USER}:${USER}" "${USER_CONFIG_DIR}"
        fi
    done

    log_success "Configuration setup completed"
    return 0
}

# Main installation process
main() {
    local start_time=$(date +%s)

    # Run installation steps
    check_system_requirements || exit 1
    install_dependencies || exit 1
    build_project || exit 1
    install_shell || exit 1
    setup_configuration || exit 1

    # Cleanup
    log_info "Cleaning up..."
    rm -rf build

    # Calculate installation time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Final success message
    log_success "Installation completed successfully in ${duration} seconds!"
    log_info "You can now run 'zenshell' to start the shell"
    log_info "Configuration files are located in ~/.zencr/"
    log_info "System-wide configuration is in /etc/zencr/"
    log_info "Installation log is available at: ${LOG_FILE}"
}

# Start installation
main