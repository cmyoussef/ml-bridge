cmake_minimum_required(VERSION 3.0)

project(ImageBridge)

# Find Nuke
set(NUKE_ROOT $ENV{BOB_WORLD_SLOT_nuke_nuke})
find_path(NUKE_INCLUDE_DIR DDImage/Op.h "${NUKE_ROOT}/include")
find_library(DDIMAGE_LIBRARY DDImage PATHS ${NUKE_ROOT})
get_filename_component(NUKE_LIBRARY_DIR ${DDIMAGE_LIBRARY} PATH)

# Build the plugin
add_library(ImageBridge SHARED ImageBridge.cpp)

target_include_directories(ImageBridge PRIVATE ${NUKE_INCLUDE_DIR})
target_link_directories(ImageBridge PRIVATE ${NUKE_LIBRARY_DIR})
target_link_libraries(ImageBridge DDImage)

# Install
install(TARGETS ImageBridge DESTINATION lib/nuke)