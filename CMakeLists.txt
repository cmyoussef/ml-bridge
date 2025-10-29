cmake_minimum_required(VERSION 3.10)
project(ml-bridge VERSION 1.0.0)

# Global settings
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_POSITION_INDEPENDENT_CODE True)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcolor-diagnostics")
endif()

# Nuke Installation Path
if(NOT NUKE_INSTALL_PATH)
    message(FATAL_ERROR "NUKE_INSTALL_PATH not set. Use -DNUKE_INSTALL_PATH=/path/to/Nuke")
endif()

message(STATUS "ml-bridge: Nuke viewer to knob bridge")
message(STATUS "  Nuke path: ${NUKE_INSTALL_PATH}")

# Find DDImage library
find_library(DDIMAGE_LIBRARY 
    NAMES DDImage libDDImage
    PATHS ${NUKE_INSTALL_PATH}
    NO_DEFAULT_PATH
)

if(NOT DDIMAGE_LIBRARY)
    message(FATAL_ERROR "DDImage library not found in ${NUKE_INSTALL_PATH}")
endif()

message(STATUS "  DDImage: ${DDIMAGE_LIBRARY}")

# Source files - now in src/ directory
set(SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/plugins/ImageBridge.cpp
)

# Create plugin
add_library(ImageBridge SHARED ${SOURCES})

# Remove lib prefix
set_target_properties(ImageBridge PROPERTIES PREFIX "")

# Include directories
target_include_directories(ImageBridge PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${NUKE_INSTALL_PATH}/include
)

# Link DDImage
target_link_libraries(ImageBridge ${DDIMAGE_LIBRARY})

# Platform specific
if(WIN32)
    set_target_properties(ImageBridge PROPERTIES SUFFIX ".dll")
else()
    set_target_properties(ImageBridge PROPERTIES SUFFIX ".so")
    if(APPLE)
        set_target_properties(ImageBridge PROPERTIES
            SUFFIX ".dylib"
            INSTALL_RPATH "@loader_path;${NUKE_INSTALL_PATH}"
        )
    endif()
endif()

message(STATUS "  Plugin: ImageBridge")
message(STATUS "  Output: ${CMAKE_BINARY_DIR}/ImageBridge.so")
