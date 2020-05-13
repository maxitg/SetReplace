# This file is only intended to provide syntax and error highlighting in IDEs that use CMake.

cmake_minimum_required(VERSION 3.16)
project(SetReplace)

set(CMAKE_CXX_FLAGS "-std=c++17")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake/Mathematica ${CMAKE_MODULE_PATH})

find_package(Mathematica REQUIRED)

include_directories(${Mathematica_WolframLibrary_INCLUDE_DIR})

file(GLOB cppsources libSetReplace/*.cpp libSetReplace/*.hpp)

add_library(SetReplace ${cppsources})
