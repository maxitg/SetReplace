cmake_minimum_required(VERSION 3.13)
project(SetReplace
    VERSION 0.3.0
    LANGUAGES CXX)
message(STATUS "${PROJECT_NAME} version: ${PROJECT_VERSION}")

option(SET_REPLACE_BUILD_TESTING "Enable cpp testing." OFF)
include(GNUInstallDirs) # Define CMAKE_INSTALL_xxx: LIBDIR, INCLUDEDIR
set(SetReplace_export_file "${PROJECT_BINARY_DIR}/SetReplaceTargets.cmake")

set(default_build_type "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
    set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
        STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY
        STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 17)
    message(STATUS "${PROJECT_NAME} using CMAKE_CXX_STANDARD: ${CMAKE_CXX_STANDARD}")
endif()

# Set extra compile options
option(SET_REPLACE_ENABLE_ALLWARNINGS
       "Add all compiler warnings to the C++ targets"
       OFF)
if(MSVC)
  list(APPEND SET_REPLACE_DEFAULT_COMPILE_OPTIONS /EHsc)
  if(SET_REPLACE_ENABLE_ALLWARNINGS)
    list(APPEND SET_REPLACE_DEFAULT_COMPILE_OPTIONS /W4 /WX)
  endif()
else()
  if(SET_REPLACE_ENABLE_ALLWARNINGS)
    list(APPEND SET_REPLACE_DEFAULT_COMPILE_OPTIONS
         -Wall -Wextra -Werror -pedantic -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wdisabled-optimization -Wformat=2
         -Winit-self -Wmissing-include-dirs -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow
         -Wsign-promo -Wswitch-default -Wundef -Wno-unused)
  endif()
endif()

set(SET_REPLACE_EXTRA_COMPILE_OPTIONS CACHE STRING "Add extra compile options to the C++ targets")
set(SET_REPLACE_COMPILE_OPTIONS_OVERRIDE CACHE STRING "Overwrite compile options for the C++ targets")
if(SET_REPLACE_COMPILE_OPTIONS_OVERRIDE)
  set(SET_REPLACE_COMPILE_OPTIONS ${SET_REPLACE_COMPILE_OPTIONS_OVERRIDE})
else()
  set(SET_REPLACE_COMPILE_OPTIONS ${SET_REPLACE_DEFAULT_COMPILE_OPTIONS} ${SET_REPLACE_EXTRA_COMPILE_OPTIONS})
endif()

message(STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")

message(STATUS "SET_REPLACE_BUILD_TESTING: ${SET_REPLACE_BUILD_TESTING}")
message(STATUS "SET_REPLACE_COMPILE_OPTIONS: ${SET_REPLACE_COMPILE_OPTIONS}")

set(libSetReplace_headers
    Parallelism.hpp
    IDTypes.hpp
    Rule.hpp
    TokenEventGraph.hpp
    AtomsIndex.hpp
    HypergraphMatcher.hpp
    HypergraphSubstitutionSystem.hpp
    WolframLanguageAPI.hpp
    )
set(libSetReplace_sources
    Parallelism.cpp
    TokenEventGraph.cpp
    AtomsIndex.cpp
    HypergraphMatcher.cpp
    HypergraphSubstitutionSystem.cpp
    WolframLanguageAPI.cpp
    )
list(TRANSFORM libSetReplace_headers PREPEND "libSetReplace/")
list(TRANSFORM libSetReplace_sources PREPEND "libSetReplace/")

add_library(SetReplace ${libSetReplace_sources})
target_include_directories(SetReplace PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libSetReplace>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
  )
target_compile_options(SetReplace PRIVATE ${SET_REPLACE_COMPILE_OPTIONS})

set(SET_REPLACE_LIBRARIES SetReplace)

install(TARGETS ${SET_REPLACE_LIBRARIES}
        EXPORT SetReplaceTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT runtime
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT runtime
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT development
        )

install(FILES ${libSetReplace_headers}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/SetReplace
  COMPONENT development
  )

# export to the build tree
export( TARGETS ${SET_REPLACE_LIBRARIES}
  NAMESPACE SetReplace::
  APPEND FILE ${SetReplace_export_file})

if(SET_REPLACE_BUILD_TESTING)
  target_compile_definitions(SetReplace PUBLIC LIBSETREPLACE_BUILD_TESTING)

  enable_testing()
  set(INSTALL_GTEST OFF)
  set(CMAKE_POLICY_DEFAULT_CMP0077 NEW) # Propagate INSTALL_GTEST=OFF to subproject
  set(GTEST_LIBRARIES gtest gtest_main)
  include(GoogleTest)
  #############################################################################
  # Fetch GTest
  include(FetchContent)

  FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG main
  )

  set(CMAKE_POLICY_DEFAULT_CMP0048 NEW) # google test raises warning about it
  FetchContent_GetProperties(googletest)
  if(NOT googletest_POPULATED)
    FetchContent_Populate(googletest)
    add_subdirectory(${googletest_SOURCE_DIR} ${googletest_BINARY_DIR})
  endif()
  #############################################################################

  add_subdirectory(libSetReplace/test)
endif()

# INSTALL
set(install_cmake_dir "${CMAKE_INSTALL_LIBDIR}/cmake/SetReplace")

install (EXPORT SetReplaceTargets
  NAMESPACE SetReplace::
  DESTINATION ${install_cmake_dir} )

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/cmake/SetReplaceConfig.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/SetReplaceConfigVersion.cmake
  DESTINATION ${install_cmake_dir} )

include(CMakePackageConfigHelpers)

write_basic_package_version_file(SetReplaceConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion)

# Build tree
set(SetReplace_TARGETS_FILE ${SetReplace_export_file})
configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/SetReplaceConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/SetReplaceConfig.cmake
  INSTALL_DESTINATION ${install_cmake_dir}
  PATH_VARS SetReplace_TARGETS_FILE
  NO_CHECK_REQUIRED_COMPONENTS_MACRO # SetReplace does not provide components
  INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}
  )

# Install tree
set(SetReplace_TARGETS_FILE ${CMAKE_INSTALL_PREFIX}/${install_cmake_dir}/SetReplaceTargets.cmake)
configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/SetReplaceConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/cmake/SetReplaceConfig.cmake
  INSTALL_DESTINATION ${install_cmake_dir}
  PATH_VARS SetReplace_TARGETS_FILE
  NO_CHECK_REQUIRED_COMPONENTS_MACRO # SetReplace does not provide components
  )

# Add custom target to only install component: runtime (libraries)
add_custom_target(set-replace-install-runtime
  ${CMAKE_COMMAND}
  -DCMAKE_INSTALL_COMPONENT=runtime
  -P "${PROJECT_BINARY_DIR}/cmake_install.cmake"
  DEPENDS ${SET_REPLACE_LIBRARIES}
  )
message(STATUS "SET_REPLACE_LIBRARIES: ${SET_REPLACE_LIBRARIES}")
add_dependencies(set-replace-install-runtime ${SET_REPLACE_LIBRARIES})
