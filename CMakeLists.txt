cmake_minimum_required(VERSION 3.10)
project(ZenShell VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set module path
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

# Find required packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(READLINE REQUIRED readline)
pkg_check_modules(LUA REQUIRED lua5.3)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${READLINE_INCLUDE_DIRS}
    ${LUA_INCLUDE_DIRS}
)

# Source files
set(SOURCES
    src/main.cpp
    src/shell.cpp
    src/theme.cpp
)

# Create executable
add_executable(zenshell ${SOURCES})

# Link libraries
target_link_libraries(zenshell
    PRIVATE
    ${READLINE_LIBRARIES}
    ${LUA_LIBRARIES}
)

# Install target
install(TARGETS zenshell DESTINATION bin)
install(DIRECTORY plugins/ DESTINATION share/zencr/plugins) 