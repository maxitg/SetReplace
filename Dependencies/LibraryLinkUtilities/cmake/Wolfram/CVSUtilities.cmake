# Wolfram/CVSUtilities.cmake
#
# A collection of functions for easy checkout of CVS dependencies, specifically for paclets developed at Wolfram.
#

#Helper function to check whether given CVS module exists.
function(cvsmoduleQ MODULE WORKINGDIR RES)
	execute_process(
			COMMAND cvs -d $ENV{CVSROOT} rdiff -r HEAD ${MODULE}
			WORKING_DIRECTORY ${WORKINGDIR}
			RESULT_VARIABLE _RES
			OUTPUT_QUIET ERROR_QUIET
	)
	if("${_RES}" STREQUAL "0")
		set(${RES} TRUE PARENT_SCOPE)
	else()
		set(${RES} FALSE PARENT_SCOPE)
	endif()
endfunction()

# Helper function to download content from CVS.
function(download_cvs_content content_name download_path module_path DOWNLOAD_LOCATION_OUT)
	include(FetchContent)
	FetchContent_declare(
			${content_name}
			SOURCE_DIR "${download_path}"
			CVS_REPOSITORY $ENV{CVSROOT}
			CVS_MODULE "${module_path}"
	)
	string(TOLOWER ${content_name} lc_content_name)
	FetchContent_getproperties(${content_name})
	if(NOT ${lc_content_name}_POPULATED)
		message(STATUS "Downloading CVS module: ${module_path}")
		FetchContent_populate(${content_name})
	endif()
	# store the download location in a variable
	set(${DOWNLOAD_LOCATION_OUT} "${${lc_content_name}_SOURCE_DIR}" PARENT_SCOPE)
endfunction()

# Download a library from Wolfram's CVS repository and set PACKAGE_LOCATION to the download location.
# If a Source directory exists in the component root directory and DOWNLOAD_CVS_SOURCE is ON, it will be downloaded.
function(get_library_from_cvs PACKAGE_NAME PACKAGE_VERSION PACKAGE_SYSTEM_ID PACKAGE_BUILD_PLATFORM PACKAGE_LOCATION)

	message(STATUS "Looking for CVS library: ${PACKAGE_NAME} version ${PACKAGE_VERSION}")

	# Specifying false value for SystemId or BuildPlatform allows all systems or platforms to be downloaded.
	set(_PACKAGE_PATH_SUFFIX ${PACKAGE_VERSION})
	if(PACKAGE_SYSTEM_ID)
		set(_PACKAGE_PATH_SUFFIX ${_PACKAGE_PATH_SUFFIX}/${PACKAGE_SYSTEM_ID})
		if(PACKAGE_BUILD_PLATFORM)
			set(_PACKAGE_PATH_SUFFIX ${_PACKAGE_PATH_SUFFIX}/${PACKAGE_BUILD_PLATFORM})
		endif()
	endif()

	# Download component library
	download_cvs_content(${PACKAGE_NAME}
	                     "${${PACKAGE_LOCATION}}/${_PACKAGE_PATH_SUFFIX}"
	                     "Components/${PACKAGE_NAME}/${_PACKAGE_PATH_SUFFIX}"
	                     _PACKAGE_LOCATION
	                     )

	set(${PACKAGE_LOCATION} "${_PACKAGE_LOCATION}" PARENT_SCOPE)
	message(STATUS "${PACKAGE_NAME} downloaded to ${_PACKAGE_LOCATION}")

	if(DOWNLOAD_CVS_SOURCE)
		# Check if a Source directory exists
		cvsmoduleQ(Components/${PACKAGE_NAME}/${PACKAGE_VERSION}/Source "${${PACKAGE_LOCATION}}" HAS_SOURCE)
		if(HAS_SOURCE)
			# Download component source
			download_cvs_content(${PACKAGE_NAME}_SOURCE
			                     "${${PACKAGE_LOCATION}}/${PACKAGE_VERSION}/Source"
			                     "Components/${PACKAGE_NAME}/${PACKAGE_VERSION}/Source"
			                     _PACKAGE_SOURCE_LOCATION
			                     )
		endif()
	endif()
endfunction()

# Splits comma delimited string STR and saves list to variable LIST
function(split_string_to_list STR LIST)
	string(REPLACE " " "" _STR ${STR})
	string(REPLACE "," ";" _STR ${_STR})
	set(${LIST} ${_STR} PARENT_SCOPE)
endfunction()

# Finds library.conf and for each library therein sets:
# ${LIBRARY_NAME}_SYSTEMID
# ${LIBRARY_NAME}_VERSION
# ${LIBRARY_NAME}_BUILD_PLATFORM
# Also sets DOWNLOAD_CVS_SOURCE variable to control Source download (default is OFF for Release config, ON otherwise).
function(find_and_parse_library_conf)
	if(NOT DEFINED DOWNLOAD_CVS_SOURCE)
		if("${CMAKE_BUILD_TYPE}" STREQUAL Release)
			set(DOWNLOAD_CVS_SOURCE OFF CACHE BOOL "Download CVS Source directory for all dependencies if it exists.")
		else()
			set(DOWNLOAD_CVS_SOURCE ON CACHE BOOL "Download CVS Source directory for all dependencies if it exists.")
		endif()
	endif()

	# path to library.conf. Located in scripts directory by default, but custom location can be passed in.
	if(ARGC GREATER_EQUAL 1)
		set(LIBRARY_CONF "${ARGV0}")
	else()
		set(LIBRARY_CONF "${CMAKE_CURRENT_SOURCE_DIR}/scripts/library.conf")
	endif()
	if(NOT EXISTS ${LIBRARY_CONF})
		message(FATAL_ERROR "Unable to find ${LIBRARY_CONF}")
	endif()

	file(STRINGS ${LIBRARY_CONF} _LIBRARY_CONF_STRINGS)
	# lines beginning with '#' shall be ignored.
	list(FILTER _LIBRARY_CONF_STRINGS EXCLUDE REGEX "^#")

	set(_LIBRARY_CONF_LIBRARY_LIST ${_LIBRARY_CONF_STRINGS})
	list(FILTER _LIBRARY_CONF_LIBRARY_LIST INCLUDE REGEX "\\[Library\\]")

	string(REGEX REPLACE
	       "\\[Library\\][ \t]+(.*)" "\\1"
	       _LIBRARY_CONF_LIBRARY_LIST "${_LIBRARY_CONF_LIBRARY_LIST}"
	       )
	split_string_to_list(${_LIBRARY_CONF_LIBRARY_LIST} _LIBRARY_CONF_LIBRARY_LIST)

	detect_system_id(SYSTEMID)

	foreach(LIBRARY ${_LIBRARY_CONF_LIBRARY_LIST})
		string(TOUPPER ${LIBRARY} _LIBRARY)

		set(LIB_SYSTEMID ${_LIBRARY}_SYSTEMID)
		set(LIB_VERSION ${_LIBRARY}_VERSION)
		set(LIB_BUILD_PLATFORM ${_LIBRARY}_BUILD_PLATFORM)

		if(NOT ${LIB_SYSTEMID})
			set(${LIB_SYSTEMID} ${SYSTEMID})
		endif()

		set(_LIBRARY_CONF_LIBRARY_STRING ${_LIBRARY_CONF_STRINGS})
		list(FILTER _LIBRARY_CONF_LIBRARY_STRING INCLUDE REGEX "${${LIB_SYSTEMID}}[ \t]+${LIBRARY}")

		if(NOT _LIBRARY_CONF_LIBRARY_STRING)
			list(APPEND UNUSED_LIBRARIES ${LIBRARY})
			message(STATUS "Skipping library ${LIBRARY}")
			continue()
		endif()

		string(REGEX REPLACE
		       "${${LIB_SYSTEMID}}[ \t]+${LIBRARY}[ \t]+([A-Za-z0-9.]+)[ \t]+([A-Za-z0-9_\\-]+)" "\\1;\\2"
		       _LIB_VERSION_BUILD_PLATFORM "${_LIBRARY_CONF_LIBRARY_STRING}"
		       )

		list(GET _LIB_VERSION_BUILD_PLATFORM 0 _LIB_VERSION)
		list(GET _LIB_VERSION_BUILD_PLATFORM 1 _LIB_BUILD_PLATFORM)

		set(${LIB_VERSION} ${_LIB_VERSION} PARENT_SCOPE)
		set(${LIB_BUILD_PLATFORM} ${_LIB_BUILD_PLATFORM} PARENT_SCOPE)
		set(${LIB_SYSTEMID} ${${LIB_SYSTEMID}} PARENT_SCOPE)
	endforeach()
endfunction()

# Resolve full path to a CVS dependency, downloading if necessary
# Prioritize ${LIB_NAME}_DIR, ${LIB_NAME}_LOCATION, CVS_COMPONENTS_DIR, then CVS download
# Do not download if ${LIB_NAME}_DIR or ${LIB_NAME}_LOCATION are set
# ${LIB_NAME}_VERSION|SYSTEMID|BUILD_PLATFORM are expected to be previously set
function(find_cvs_dependency LIB_NAME)

	# helper variables
	string(TOUPPER ${LIB_NAME} _LIB_NAME)
	set(LIB_DIR "${${_LIB_NAME}_DIR}")
	set(LIB_LOCATION "${${_LIB_NAME}_LOCATION}")
	set(LIB_VERSION ${${_LIB_NAME}_VERSION})
	set(LIB_SYSTEMID ${${_LIB_NAME}_SYSTEMID})
	set(LIB_BUILD_PLATFORM ${${_LIB_NAME}_BUILD_PLATFORM})
	set(_LIB_DIR_SUFFIX ${LIB_VERSION}/${LIB_SYSTEMID}/${LIB_BUILD_PLATFORM})

	if(NOT LIB_SYSTEMID)
		message(STATUS "[find_cvs_dependency] ${LIB_NAME}_SYSTEMID not defined. Returning.")
		return()
	endif()

	# Check if there is a full path to the dependency with version, system id and build platform.
	if(NOT ${LIB_DIR} STREQUAL "")
		if(NOT EXISTS ${LIB_DIR})
			message(FATAL_ERROR "Specified full path to Lib does not exist: ${LIB_DIR}")
		endif()
		return()
	endif()

	# Check if there is a path to the Lib component
	if(NOT ${LIB_LOCATION} STREQUAL "")
		if(NOT EXISTS ${LIB_LOCATION})
			message(FATAL_ERROR "Specified location of Lib does not exist: ${LIB_LOCATION}")
		elseif(EXISTS ${LIB_LOCATION}/${_LIB_DIR_SUFFIX})
			set(${_LIB_NAME}_DIR ${LIB_LOCATION}/${_LIB_DIR_SUFFIX} PARENT_SCOPE)
			return()
		endif()
	endif()

	# Check if there is a path to CVS modules
	if(CVS_COMPONENTS_DIR)
		set(_CVS_COMPONENTS_DIR ${CVS_COMPONENTS_DIR})
	elseif(DEFINED ENV{CVS_COMPONENTS_DIR})
		set(_CVS_COMPONENTS_DIR $ENV{CVS_COMPONENTS_DIR})
	endif()

	if(_CVS_COMPONENTS_DIR)
		if(NOT EXISTS ${_CVS_COMPONENTS_DIR})
			message(FATAL_ERROR "Specified location of CVS components does not exist: ${_CVS_COMPONENTS_DIR}")
		elseif(EXISTS ${_CVS_COMPONENTS_DIR}/${LIB_NAME}/${_LIB_DIR_SUFFIX})
			set(${_LIB_NAME}_DIR ${_CVS_COMPONENTS_DIR}/${LIB_NAME}/${_LIB_DIR_SUFFIX} PARENT_SCOPE)
			return()
		endif()
	endif()

	# Finally download component from cvs
	# Set location of library sources checked out from cvs
	set(LIB_LOCATION "${CMAKE_BINARY_DIR}/Components/${LIB_NAME}")
	set(${_LIB_NAME}_LOCATION ${LIB_LOCATION} CACHE PATH "Location of ${LIB_NAME} root directory.")

	get_library_from_cvs(${LIB_NAME} ${LIB_VERSION} ${LIB_SYSTEMID} ${LIB_BUILD_PLATFORM} LIB_LOCATION)
	set(${_LIB_NAME}_DIR ${LIB_LOCATION} PARENT_SCOPE)
endfunction()
