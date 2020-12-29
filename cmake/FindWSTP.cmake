# FindWSTP.cmake
#
# Finds the Wolfram Symbolic Transfer Protocol installation
#
# This will define the following variables
#
#    WSTP_FOUND
#    WSTP_INCLUDE_DIRS
#    WSTP_LIBRARIES
#    WSTP_VERSION
#
# and the following imported target
#
#     WSTP::WSTP
#
# You can specify custom location to search for WSTP either by specifying WOLFRAM_WSTP_PATH explicitly,
# or if that variable is not set, by providing WolframLanguage_INSTALL_DIR variable with a path to a WolframLanguage installation.
#
# Author: Rafal Chojna - rafalc@wolfram.com

include(Wolfram/Common)

detect_system_id(_WOLFSTP_SYSTEMID)

if(WOLFRAM_WSTP_PATH)
	set(_WOLFSTP_LIBRARY_PATH "${WOLFRAM_WSTP_PATH}")
else()
	set(_WOLFSTP_LIBRARY_PATH "$ENV{WOLFRAM_WSTP_PATH}")
endif()

if(NOT _WOLFSTP_LIBRARY_PATH AND WolframLanguage_INSTALL_DIR)
	set(_WOLFSTP_LIBRARY_PATH "${WolframLanguage_INSTALL_DIR}/SystemFiles/Links/WSTP/DeveloperKit/${_WOLFSTP_SYSTEMID}/CompilerAdditions")
endif()

if(NOT _WOLFSTP_LIBRARY_PATH AND Mathematica_INSTALL_DIR)
	set(_WOLFSTP_LIBRARY_PATH "${Mathematica_INSTALL_DIR}/SystemFiles/Links/WSTP/DeveloperKit/${_WOLFSTP_SYSTEMID}/CompilerAdditions")
endif()

if(_WOLFSTP_LIBRARY_PATH)
	set(_WOLFSTP_SEARCH_OPTS NO_DEFAULT_PATH)
else()
	set(_WOLFSTP_SEARCH_OPTS)
endif()

find_path(WSTP_INCLUDE_DIR
	NAMES wstp.h
	PATHS "${_WOLFSTP_LIBRARY_PATH}"
	${_WOLFSTP_SEARCH_OPTS}
	DOC "Path to the wstp.h"
)

if(WSTP_INCLUDE_DIR)
	file(STRINGS "${WSTP_INCLUDE_DIR}/wstp.h" _WOLFSTP_HEADER_CONTENTS REGEX "#define WS[A-Z]+ ")
	string(REGEX REPLACE ".*#define WSINTERFACE ([0-9]+).*" "\\1" WSTP_VERSION_MAJOR "${_WOLFSTP_HEADER_CONTENTS}")
	string(REGEX REPLACE ".*#define WSREVISION ([0-9]+).*" "\\1" WSTP_VERSION_MINOR "${_WOLFSTP_HEADER_CONTENTS}")

	set(WSTP_VERSION_STRING "${WSTP_VERSION_MAJOR}.${WSTP_VERSION_MINOR}")

	get_wstp_library_name(${WSTP_VERSION_MAJOR} _WOLFSTP_LIB_NAME)

	find_library(WSTP_LIBRARY
		NAMES "wstp" ${_WOLFSTP_LIB_NAME}
		PATHS "${_WOLFSTP_LIBRARY_PATH}"
		${_WOLFSTP_SEARCH_OPTS}
		DOC "Path to the WSTP library"
	)

	mark_as_advanced(WSTP_FOUND WSTP_INCLUDE_DIR WSTP_VERSION_MAJOR WSTP_VERSION_MINOR WSTP_VERSION_STRING)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(WSTP
	REQUIRED_VARS WSTP_LIBRARY WSTP_INCLUDE_DIR
	VERSION_VAR WSTP_VERSION_STRING
)

if (WSTP_FOUND)
	set(WSTP_INCLUDE_DIRS ${WSTP_INCLUDE_DIR})
	set(WSTP_LIBRARIES ${WSTP_LIBRARY})
endif()

if(WSTP_FOUND AND NOT TARGET WSTP::WSTP)
	add_library(WSTP::WSTP SHARED IMPORTED)
	set_target_properties(WSTP::WSTP PROPERTIES
		INTERFACE_INCLUDE_DIRECTORIES "${WSTP_INCLUDE_DIR}"
		IMPORTED_LOCATION "${WSTP_LIBRARIES}"
		IMPORTED_IMPLIB "${WSTP_LIBRARIES}"
	)
	if(APPLE)
		find_library(FOUNDATION_FRAMEWORK Foundation)
		set_target_properties(WSTP::WSTP PROPERTIES
			INTERFACE_LINK_LIBRARIES "${FOUNDATION_FRAMEWORK};c++"
			IMPORTED_LOCATION "${WSTP_LIBRARIES}/wstp"
		)
	endif()
endif()