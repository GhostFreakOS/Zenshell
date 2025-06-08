# FindLua.cmake
# Finds the Lua library
#
# This will define the following variables:
#
#   LUA_FOUND        - True if the system has Lua
#   LUA_INCLUDE_DIRS - Lua include directory
#   LUA_LIBRARIES    - Lua libraries
#   LUA_VERSION      - Lua version

include(FindPackageHandleStandardArgs)

# Try to find Lua using pkg-config first
find_package(PkgConfig QUIET)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(PC_LUA QUIET lua5.1)
endif()

# Find the include directory
find_path(LUA_INCLUDE_DIR
    NAMES lua.h
    PATHS
        ${PC_LUA_INCLUDEDIR}
        /usr/include
        /usr/local/include
        /usr/include/lua5.1
    PATH_SUFFIXES
        lua5.1
        lua
)

# Find the library
find_library(LUA_LIBRARY
    NAMES
        lua5.1
        lua
    PATHS
        ${PC_LUA_LIBDIR}
        /usr/lib
        /usr/local/lib
)

# Get version
if(LUA_INCLUDE_DIR)
    file(STRINGS "${LUA_INCLUDE_DIR}/lua.h" LUA_VERSION_LINE
        REGEX "^#define[ \t]+LUA_VERSION_[A-Z]+[ \t]+\"[0-9]+\"")
    string(REGEX REPLACE ".*#define[ \t]+LUA_VERSION_MAJOR[ \t]+\"([0-9])\".*" "\\1" LUA_VERSION_MAJOR "${LUA_VERSION_LINE}")
    string(REGEX REPLACE ".*#define[ \t]+LUA_VERSION_MINOR[ \t]+\"([0-9])\".*" "\\1" LUA_VERSION_MINOR "${LUA_VERSION_LINE}")
    set(LUA_VERSION "${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}")
endif()

set(LUA_LIBRARIES ${LUA_LIBRARY})
set(LUA_INCLUDE_DIRS ${LUA_INCLUDE_DIR})

find_package_handle_standard_args(Lua
    REQUIRED_VARS LUA_LIBRARY LUA_INCLUDE_DIR
    VERSION_VAR LUA_VERSION
)

mark_as_advanced(LUA_INCLUDE_DIR LUA_LIBRARY) 