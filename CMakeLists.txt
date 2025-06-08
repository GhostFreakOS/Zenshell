cmake_minimum_required(VERSION 3.10)
project(ZenShell VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(Readline REQUIRED)
find_package(Lua REQUIRED)

# Include directories
include_directories(${CMAKE_SOURCE_DIR}/include)

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
    readline
    ${LUA_LIBRARIES}
)

# Install target
install(TARGETS zenshell DESTINATION bin) 