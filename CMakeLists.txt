cmake_minimum_required(VERSION 3.10)
project(MLBridge VERSION 1.0.0)

set( CMAKE_CXX_STANDARD 17 )
set( CMAKE_CXX_STANDARD_REQUIRED ON )
set( CMAKE_CXX_EXTENSIONS OFF )
set( CMAKE_CXX_VISIBILITY_PRESET hidden )
set( CMAKE_POSITION_INDEPENDENT_CODE True )

add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcolor-diagnostics")
endif()

add_subdirectory(src/plugins/ImageBridge)