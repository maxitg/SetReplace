# FindWolframLibrary.cmake
#
# Finds the Wolfram Library header files
#
# This will define the following variables
#
#    WolframLibrary_FOUND
#    WolframLibrary_INCLUDE_DIRS
#    WolframLibrary_VERSION
#
# and the following imported target
#
#     WolframLibrary::WolframLibrary
#
# You can specify custom location to search for Wolfram Library either by specifying WOLFRAM_LIBRARY_PATH explicitly,
# or if that variable is not set, by providing WolframLanguage_INSTALL_DIR variable with a path to a WolframLanguage installation.
#
# Author: Rafal Chojna - rafalc@wolfram.com


if(WOLFRAM_LIBRARY_PATH)
	set(_WOLFLIB_LIBRARY_PATH "${WOLFRAM_LIBRARY_PATH}")
else()
	set(_WOLFLIB_LIBRARY_PATH "$ENV{WOLFRAM_LIBRARY_PATH}")
endif()

if(NOT _WOLFLIB_LIBRARY_PATH AND WolframLanguage_INSTALL_DIR)
	set(_WOLFLIB_LIBRARY_PATH "${WolframLanguage_INSTALL_DIR}/SystemFiles/IncludeFiles/C")
endif()

if(NOT _WOLFLIB_LIBRARY_PATH AND Mathematica_INSTALL_DIR)
	set(_WOLFLIB_LIBRARY_PATH "${Mathematica_INSTALL_DIR}/SystemFiles/IncludeFiles/C")
endif()

if (_WOLFLIB_LIBRARY_PATH)
	set(_WOLFLIB_SEARCH_OPTS NO_DEFAULT_PATH)
else()
	set(_WOLFLIB_SEARCH_OPTS)
endif()

find_path(WolframLibrary_INCLUDE_DIR
	NAMES WolframLibrary.h
	PATHS "${_WOLFLIB_LIBRARY_PATH}"
	${_WOLFLIB_SEARCH_OPTS}
	DOC "Path to the WolframLibrary.h and other header files from Wolfram Library"
)

if(WolframLibrary_FOUND)
	file(STRINGS "${WolframLibrary_INCLUDE_DIR}/WolframLibrary.h" _WOLFLIB_HEADER_CONTENTS REGEX "#define WolframLibraryVersion ")
	string(REGEX REPLACE ".*#define WolframLibraryVersion ([0-9]+).*" "\\1" WolframLibrary_VERSION "${_WOLFLIB_HEADER_CONTENTS}")

	mark_as_advanced(WolframLibrary_FOUND WolframLibrary_INCLUDE_DIR WolframLibrary_VERSION)
	set(WolframLibrary_INCLUDE_DIRS ${WolframLibrary_INCLUDE_DIR})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WolframLibrary
	REQUIRED_VARS WolframLibrary_INCLUDE_DIR
	VERSION_VAR WolframLibrary_VERSION
)

if(WolframLibrary_FOUND AND NOT TARGET WolframLibrary::WolframLibrary)
	add_library(WolframLibrary::WolframLibrary INTERFACE IMPORTED)
	set_target_properties(WolframLibrary::WolframLibrary PROPERTIES
	INTERFACE_INCLUDE_DIRECTORIES "${WolframLibrary_INCLUDE_DIR}"
)
endif()