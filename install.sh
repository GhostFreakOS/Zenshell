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

log_debug() {
    if [ "${DEBUG}" = "true" ]; then
        echo -e "[DEBUG] $1"
    fi
}

# Create log file
LOG_FILE="/tmp/zenshell_install.log"
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>${LOG_FILE} 2>&1

# ASCII Art
zen_ascii="
${RED}███████╗███████╗███╗   ██╗
╚══███╔╝██╔════╝████╗  ██║
  ███╔╝ █████╗  ██╔██╗ ██║
 ███╔╝  ██╔══╝  ██║╚██╗██║
███████╗███████╗██║ ╚████║
╚══════╝╚══════╝╚═╝  ╚═══╝${RESET}
"

echo -e "$zen_ascii" >&3
log_info "Starting Zen Shell installation..." >&3

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "This script must be run as root or with sudo" >&3
    exit 1
fi

# Function to check if a command exists
command_exists() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Required command '$1' not found" >&3
        return 1
    fi
    return 0
}

# Function to verify system requirements
check_system_requirements() {
    log_info "Checking system requirements..." >&3
    
    # Check for minimum required disk space (500MB)
    local free_space=$(df -m . | awk 'NR==2 {print $4}')
    if [ "${free_space}" -lt 500 ]; then
        log_error "Insufficient disk space. Required: 500MB, Available: ${free_space}MB" >&3
        return 1
    fi

    # Check for minimum RAM (256MB)
    local total_ram=$(free -m | awk '/Mem:/ {print $2}')
    if [ "${total_ram}" -lt 256 ]; then
        log_error "Insufficient RAM. Required: 256MB, Available: ${total_ram}MB" >&3
        return 1
    }

    return 0
}

# Function to install package with detailed error reporting
install_package() {
    local package_name="$1"
    log_info "Installing package: ${package_name}" >&3

    if ! dpkg -l | grep -q "^ii  $package_name"; then
        apt-get install -y "$package_name" 2>&1 | tee -a "${LOG_FILE}"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            log_error "Failed to install ${package_name}. Check ${LOG_FILE} for details" >&3
            log_error "Last 5 lines of error:" >&3
            tail -n 5 "${LOG_FILE}" >&3
            return 1
        fi
        log_success "Successfully installed ${package_name}" >&3
    else
        log_info "Package ${package_name} is already installed" >&3
    fi
    return 0
}

# Update package list with error checking
update_package_list() {
    log_info "Updating package lists..." >&3
    if ! apt-get update 2>&1 | tee -a "${LOG_FILE}"; then
        log_error "Failed to update package lists. Check ${LOG_FILE} for details" >&3
        return 1
    fi
    return 0
}

# Install dependencies with detailed reporting
install_dependencies() {
    log_info "Installing dependencies..." >&3
    
    local DEPS=(
        "build-essential"
        "cmake"
        "libreadline-dev"
        "liblua5.1-0-dev"
        "pkg-config"
        "git"
    )

    local failed_deps=()
    for dep in "${DEPS[@]}"; do
        if ! install_package "$dep"; then
            failed_deps+=("$dep")
        fi
    done

    if [ ${#failed_deps[@]} -ne 0 ]; then
        log_error "Failed to install the following dependencies:" >&3
        printf '%s\n' "${failed_deps[@]}" >&3
        return 1
    fi

    return 0
}

# Configure and build with CMake
build_project() {
    log_info "Creating build directory..." >&3
    mkdir -p build || {
        log_error "Failed to create build directory" >&3
        return 1
    }
    cd build

    log_info "Configuring with CMake..." >&3
    if ! cmake .. 2>&1 | tee -a "${LOG_FILE}"; then
        log_error "CMake configuration failed. Check ${LOG_FILE} for details" >&3
        cd ..
        return 1
    fi

    log_info "Building Zen Shell..." >&3
    if ! make -j$(nproc) 2>&1 | tee -a "${LOG_FILE}"; then
        log_error "Build failed. Check ${LOG_FILE} for details" >&3
        cd ..
        return 1
    fi

    cd ..
    return 0
}

# Install the built files
install_files() {
    log_info "Installing Zen Shell..." >&3
    
    cd build
    if ! make install 2>&1 | tee -a "${LOG_FILE}"; then
        log_error "Installation failed. Check ${LOG_FILE} for details" >&3
        cd ..
        return 1
    }
    cd ..

    return 0
}

# Setup configuration
setup_configuration() {
    log_info "Setting up configuration..." >&3
    
    local CONFIG_DIR="/etc/zencr"
    local PLUGINS_DIR="${CONFIG_DIR}/plugins"

    # Create system directories
    mkdir -p "${CONFIG_DIR}" "${PLUGINS_DIR}" || {
        log_error "Failed to create configuration directories" >&3
        return 1
    }

    # Copy configuration files
    if [ ! -f "${CONFIG_DIR}/config.lua" ]; then
        cp config.lua "${CONFIG_DIR}/" 2>&1 | tee -a "${LOG_FILE}" || {
            log_error "Failed to copy config.lua" >&3
            return 1
        }
    fi

    # Copy plugins
    cp -r plugins/* "${PLUGINS_DIR}/" 2>&1 | tee -a "${LOG_FILE}" || {
        log_error "Failed to copy plugins" >&3
        return 1
    }

    # Set permissions
    chown -R root:root "${CONFIG_DIR}"
    chmod -R 755 "${CONFIG_DIR}"

    # Setup user configurations
    for USER_HOME in /home/*; do
        if [ -d "${USER_HOME}" ]; then
            local USER=$(basename "${USER_HOME}")
            local USER_CONFIG_DIR="${USER_HOME}/.zencr"
            
            mkdir -p "${USER_CONFIG_DIR}/plugins" || {
                log_error "Failed to create user config directory for ${USER}" >&3
                continue
            }
            
            if [ ! -f "${USER_CONFIG_DIR}/config.lua" ]; then
                cp "${CONFIG_DIR}/config.lua" "${USER_CONFIG_DIR}/" || {
                    log_error "Failed to copy config for user ${USER}" >&3
                    continue
                }
            fi
            
            chown -R "${USER}:${USER}" "${USER_CONFIG_DIR}" || {
                log_error "Failed to set permissions for user ${USER}" >&3
                continue
            }
        fi
    done

    return 0
}

# Main installation process
main() {
    local start_time=$(date +%s)

    # Check system requirements
    check_system_requirements || exit 1

    # Update and install dependencies
    update_package_list || exit 1
    install_dependencies || exit 1

    # Build and install
    build_project || exit 1
    install_files || exit 1
    setup_configuration || exit 1

    # Cleanup
    log_info "Cleaning up..." >&3
    rm -rf build

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_success "Installation completed successfully in ${duration} seconds!" >&3
    log_info "You can now run 'zenshell' to start the shell" >&3
    log_info "Configuration files are located in ~/.zencr/" >&3
    log_info "System-wide configuration is in /etc/zencr/" >&3
    log_info "Installation log is available at: ${LOG_FILE}" >&3
}

# Run main installation
main

exit 0