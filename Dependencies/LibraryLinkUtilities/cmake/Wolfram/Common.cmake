# Wolfram/Common.cmake
#
# A collection of short utility functions that may be helpful for Mathematica paclets that use CMake.
# Most of the functions here are specifically tailored for paclets developed at Wolfram but the following utilities might be useful in general case:
#
# set_machine_flags
# set_rpath
# set_default_cxx_properties
# set_windows_static_runtime
# install_dependency_files

include_guard()

function(get_default_mathematica_dir MATHEMATICA_VERSION DEFAULT_MATHEMATICA_INSTALL_DIR)
	set(_M_INSTALL_DIR NOTFOUND)
	if(APPLE)
		find_path(_M_INSTALL_DIR "Contents" PATHS
			"/Applications/Mathematica ${MATHEMATICA_VERSION}.app"
			"/Applications/Mathematica.app"
			)
		set(_M_INSTALL_DIR "${_M_INSTALL_DIR}/Contents")
	elseif(WIN32)
		set(_M_INSTALL_DIR "C:/Program\ Files/Wolfram\ Research/Mathematica/${MATHEMATICA_VERSION}")
	else()
		set(_M_INSTALL_DIR "/usr/local/Wolfram/Mathematica/${MATHEMATICA_VERSION}")
	endif()
	if(NOT IS_DIRECTORY "${_M_INSTALL_DIR}" AND IS_DIRECTORY "$ENV{MATHEMATICA_HOME}")
		set(_M_INSTALL_DIR "$ENV{MATHEMATICA_HOME}")
	endif()
	set(${DEFAULT_MATHEMATICA_INSTALL_DIR} "${_M_INSTALL_DIR}" PARENT_SCOPE)
endfunction()

function(get_wolfram_product_default_dirs PRODUCT_NAME PRODUCT_VERSION DEFAULT_PRODUCT_INSTALL_DIR)
	set(_DEFAULT_INSTALL_DIR NOTFOUND)
	if(APPLE)
		set(_DEFAULT_INSTALL_DIR
			"/Applications/${PRODUCT_NAME} ${PRODUCT_VERSION}.app"
			"/Applications/${PRODUCT_NAME}.app")
	elseif(WIN32)
		set(_DEFAULT_INSTALL_DIR "C:/Program\ Files/Wolfram\ Research/${PRODUCT_NAME}/${PRODUCT_VERSION}")
	else()
		set(_DEFAULT_INSTALL_DIR "/usr/local/Wolfram/${PRODUCT_NAME}/${PRODUCT_VERSION}")
	endif()
	set(${DEFAULT_PRODUCT_INSTALL_DIR} "${_DEFAULT_INSTALL_DIR}" PARENT_SCOPE)
endfunction()

function(get_default_wolfram_dirs WL_VERSION DEFAULT_INSTALL_DIRS)
	get_wolfram_product_default_dirs(WolframDesktop ${WL_VERSION} _WD_INSTALL_DIRS)
	get_wolfram_product_default_dirs(Mathematica ${WL_VERSION} _M_INSTALL_DIRS)
	get_wolfram_product_default_dirs(WolframEngine ${WL_VERSION} _WE_INSTALL_DIRS)
	set(${DEFAULT_INSTALL_DIRS}
		"${_WD_INSTALL_DIRS}"
		"${_M_INSTALL_DIRS}"
		"${_WE_INSTALL_DIRS}"
		PARENT_SCOPE)
endfunction()

function(detect_system_id DETECTED_SYSTEM_ID)
	if(NOT ${DETECTED_SYSTEM_ID})
		#set system id and build platform
		set(BITNESS 32)
		if(CMAKE_SIZEOF_VOID_P EQUAL 8)
			set(BITNESS 64)
		endif()

		set(INITIAL_SYSTEMID NOTFOUND)

		# Determine the current machine's systemid.
		if(CMAKE_C_COMPILER MATCHES "androideabi")
			set(INITIAL_SYSTEMID Android)
		elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm*")
			set(INITIAL_SYSTEMID Linux-ARM)
		elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND BITNESS EQUAL 64)
			set(INITIAL_SYSTEMID Linux-x86-64)
		elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND BITNESS EQUAL 32)
			set(INITIAL_SYSTEMID Linux)
		elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows" AND BITNESS EQUAL 64)
			set(INITIAL_SYSTEMID Windows-x86-64)
		elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows" AND BITNESS EQUAL 32)
			set(INITIAL_SYSTEMID Windows)
		elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND BITNESS EQUAL 64)
			set(INITIAL_SYSTEMID MacOSX-x86-64)
		elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND BITNESS EQUAL 32)
			set(INITIAL_SYSTEMID MacOSX-x86)
		endif()

		if(NOT INITIAL_SYSTEMID)
			message(FATAL_ERROR "Unable to determine System ID.")
		endif()

		set(${DETECTED_SYSTEM_ID} "${INITIAL_SYSTEMID}" PARENT_SCOPE)
	endif()
endfunction()

function(detect_build_platform DETECTED_BUILD_PLATFORM)
	# Determine the current machine's build platform.
	set(BUILD_PLATFORM Indeterminate)
	if(CMAKE_SYSTEM_NAME STREQUAL "Android")
		if(CMAKE_C_COMPILER_VERSION VERSION_LESS 4.9)
			set(BUILD_PLATFORM_ERROR "Android build with gcc version less than 4.9")
		else()
			set(BUILD_PLATFORM android-16-gcc4.9)
		endif()
	elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm*" AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
		if(CMAKE_C_COMPILER_ID STREQUAL "GNU" AND CMAKE_C_COMPILER_VERSION VERSION_LESS 4.7)
			set(BUILD_PLATFORM_ERROR "Arm build with gcc less than 4.7")
		elseif(CMAKE_C_COMPILER AND NOT CMAKE_C_COMPILER_ID STREQUAL "GNU")
			set(BUILD_PLATFORM_ERROR "Arm build with non-gnu compiler")
		else()
			#at some point might be smart to dynamically construct this build platform, but
			#for now it's all we build ARM on so it should be okay
			set(BUILD_PLATFORM armv6-glibc2.19-gcc4.9)
		endif()
	elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
		if(CMAKE_C_COMPILER_ID STREQUAL "GNU" AND CMAKE_C_COMPILER_VERSION VERSION_LESS 5.2)
			set(BUILD_PLATFORM_ERROR "Linux build with gcc less than 5.2")
		elseif(CMAKE_C_COMPILER AND NOT CMAKE_C_COMPILER_ID STREQUAL "GNU")
			set(BUILD_PLATFORM_ERROR "Linux build with non-gnu compiler")
		else()
			set(BUILD_PLATFORM scientific6-gcc4.8)
		endif()
	elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
		if((NOT CMAKE_C_COMPILER) OR (NOT MSVC_VERSION LESS 1900))
			if(MSVC_VERSION EQUAL 1900)
				set(BUILD_PLATFORM vc140)
			elseif(MSVC_VERSION GREATER_EQUAL 1910)
				set(BUILD_PLATFORM vc141)
			endif()
		else()
			set(BUILD_PLATFORM_ERROR "Windows build without VS 2015 or greater.")
		endif()
	elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
		if(CMAKE_SYSTEM_VERSION VERSION_LESS 10.9)
			set(BUILD_PLATFORM_ERROR "OSX build on OSX less than 10.9")
		else()
			set(BUILD_PLATFORM libcxx-min10.9)
		endif()
	else()
		set(BUILD_PLATFORM_ERROR "Unrecognized system type.")
	endif()

	if(BUILD_PLATFORM STREQUAL "Indeterminate")
		message(FATAL_ERROR "Unable to determine Build Platform. Reason: ${BUILD_PLATFORM_ERROR}")
	endif()

	set(${DETECTED_BUILD_PLATFORM} "${BUILD_PLATFORM}" PARENT_SCOPE)
endfunction()

#set WSTP library name depending on the platform
function(get_wstp_library_name WSTP_INTERFACE_VERSION WSTP_LIB_NAME)

	detect_system_id(SYSTEM_ID)

	set(WSTP_LIBRARY NOTFOUND)
	if(SYSTEM_ID STREQUAL "MacOSX-x86-64")
		set(WSTP_LIBRARY "WSTPi${WSTP_INTERFACE_VERSION}")
	elseif(SYSTEM_ID STREQUAL "Linux" OR SYSTEM_ID STREQUAL "Linux-ARM" OR SYSTEM_ID STREQUAL "Windows")
		set(WSTP_LIBRARY "WSTP32i${WSTP_INTERFACE_VERSION}")
	elseif(SYSTEM_ID STREQUAL "Linux-x86-64" OR SYSTEM_ID STREQUAL "Windows-x86-64")
		set(WSTP_LIBRARY "WSTP64i${WSTP_INTERFACE_VERSION}")
	endif()

	if(NOT WSTP_LIBRARY)
		message(FATAL_ERROR "Unable to determine WSTP library name for system: ${SYSTEM_ID}")
	endif()

	set(${WSTP_LIB_NAME} "${WSTP_LIBRARY}" PARENT_SCOPE)
endfunction()

# On linux, set the linker flags to use the nonshared version of stdc++ if found.
# This supports old runtimes lacking new c++ language features.
function(add_cpp_nonshared_library TARGET_NAME)
	if(UNIX)
		find_library(NON_SHARED_CXX_LIB NAMES "stdc++_nonshared")
		if(NON_SHARED_CXX_LIB)
			target_link_libraries(${TARGET_NAME} PRIVATE "stdc++_nonshared")
		endif()
	endif()
endfunction()

# set machine bitness flags for given target
function(set_machine_flags TARGET_NAME)
	detect_system_id(SYSTEM_ID)

	if(SYSTEM_ID MATCHES "-x86-64")
		if(MSVC)
			set_target_properties(${TARGET_NAME} PROPERTIES LINK_FLAGS "/MACHINE:x64")
		else()
			set_target_properties(${TARGET_NAME} PROPERTIES COMPILE_FLAGS "-m64" LINK_FLAGS "-m64")
		endif()
	elseif(SYSTEM_ID MATCHES "Linux-ARM")
		target_compile_definitions(${TARGET_NAME} PUBLIC MINT_32)
		set_target_properties(${TARGET_NAME} PROPERTIES COMPILE_FLAGS "-marm -march=armv6" LINK_FLAGS "-marm -march=armv6")
	else()
		target_compile_definitions(${TARGET_NAME} PUBLIC MINT_32)
		if(MSVC)
			set_target_properties(${TARGET_NAME} PROPERTIES LINK_FLAGS "/MACHINE:x86")
		else()
			set_target_properties(${TARGET_NAME} PROPERTIES COMPILE_FLAGS "-m32" LINK_FLAGS "-m32")
		endif()
	endif()
endfunction()

# Sets rpath for a target. If second argument is false then "Wolfram-default" rpath is set:
# - $ORIGIN on Linux
# - @loader_path on Mac
# On Windows rpath does not make sense.
function(set_rpath TARGET_NAME NEW_RPATH)
	if(NOT NEW_RPATH)
		if(APPLE)
			#set the linker options to set rpath as @loader_path
			set(NEW_RPATH "@loader_path/")
		elseif(UNIX)
			#set the install_rpath to be $ORIGIN so that it automatically finds the dependencies in the current folder
			set(NEW_RPATH $ORIGIN)
		endif()
	endif ()
	set_target_properties(${TARGET_NAME} PROPERTIES INSTALL_RPATH ${NEW_RPATH})
endfunction()

# Sets SEARCH_OPTS depending on whether the variable PATH has a value.
function(set_search_opts_from_path PATH SEARCH_OPTS)
	if(${PATH})
		set(${SEARCH_OPTS} NO_DEFAULT_PATH PARENT_SCOPE)
	else()
		set(${SEARCH_OPTS} PARENT_SCOPE)
	endif()
endfunction()

# Detects whether a library is shared or static.
# This should be used to set the type in add_library() for dependency libraries.
function(detect_library_type LIBRARY TYPE_VAR)
	get_filename_component(_EXT ${LIBRARY} EXT)
	if("${_EXT}" STREQUAL "${CMAKE_SHARED_LIBRARY_SUFFIX}")
		set(${TYPE_VAR} SHARED PARENT_SCOPE)
	elseif("${_EXT}" STREQUAL "${CMAKE_STATIC_LIBRARY_SUFFIX}")
		if(MSVC)
			# On Windows, the .lib is present for both static and shared libraries, so check whether it contains exported symbols.
			# Failing that, check whether a similarly named .dll file exists in the same directory.
			execute_process(
					COMMAND dumpbin /exports ${LIBRARY}
					COMMAND grep -w Exports
					RESULT_VARIABLE _RESULT
					OUTPUT_VARIABLE _OUTPUT
			)
			if(_RESULT EQUAL 0)
				if("${_OUTPUT}" MATCHES "[ \t]*Exports[ \t\r\n]*")
					set(${TYPE_VAR} SHARED PARENT_SCOPE)
				else()
					set(${TYPE_VAR} STATIC PARENT_SCOPE)
				endif()
			else()
				get_filename_component(_PATH ${LIBRARY} DIRECTORY)
				get_filename_component(_NAME ${LIBRARY} NAME_WE)
				if(EXISTS ${_PATH}/${_NAME}.dll)
					set(${TYPE_VAR} SHARED PARENT_SCOPE)
				else()
					set(${TYPE_VAR} STATIC PARENT_SCOPE)
				endif()
			endif()
		else()
			set(${TYPE_VAR} STATIC PARENT_SCOPE)
		endif()
	else()
		set(${TYPE_VAR} UNKNOWN PARENT_SCOPE)
	endif()
endfunction()

# Creates an imported target with the given name and main target library. Fails if the library does not exist.
# The type of the target is detected from the library and used to correctly set IMPORTED_LOCATION and IMPORTED_IMPLIB.
# Creating the target with the correct type allows useful target properties to be automatically set such as TYPE, RUNTIME_OUTPUT_NAME etc.
# Optional 3rd arg is a variable to return the detected library type in.
function(add_imported_target_detect_type TARGET_NAME LIBRARY)
	fail_if_dne(${LIBRARY})
	detect_library_type(${LIBRARY} LIBRARY_TYPE)
	add_library(${TARGET_NAME} ${LIBRARY_TYPE} IMPORTED)
	# IMPORTED_LOCATION is the .dll component for SHARED targets on Windows. See: https://cmake.org/cmake/help/latest/prop_tgt/IMPORTED_LOCATION.html
	if(${LIBRARY_TYPE} STREQUAL SHARED)
		string(REPLACE ".lib" ".dll" LIBRARY_DLL "${LIBRARY}")
	else()
		set(LIBRARY_DLL ${LIBRARY})
	endif()
	# IMPORTED_IMPLIB is the .lib component for imported targets on Windows. See: https://cmake.org/cmake/help/latest/prop_tgt/IMPORTED_IMPLIB.html
	string(REPLACE ".dll" ".lib" LIBRARY_LIB "${LIBRARY}")
	set_target_properties(${TARGET_NAME} PROPERTIES
			IMPORTED_LOCATION "${LIBRARY_DLL}"
			IMPORTED_IMPLIB "${LIBRARY_LIB}"
			)
	if(ARGC GREATER 2)
		set(${ARGV2} ${LIBRARY_TYPE} PARENT_SCOPE)
	endif()
endfunction()

# Copies dependency libraries into paclet layout if the library type is SHARED (always copies on Windows).
# Optional arguments are the libraries to copy (defaults to main target file plus its dependencies).
function(install_dependency_files PACLET_NAME DEP_TARGET_NAME)
	get_target_property(_DEP_TYPE ${DEP_TARGET_NAME} TYPE)
	if("${_DEP_TYPE}" STREQUAL UNKNOWN_LIBRARY)
		get_target_property(_DEP_LIBRARY ${DEP_TARGET_NAME} IMPORTED_LOCATION)
		detect_library_type(${_DEP_LIBRARY} _DEP_TYPE)
	endif()
	if("${_DEP_TYPE}" MATCHES "SHARED(_LIBRARY)?")
		if(ARGC GREATER_EQUAL 3)
			set(DEP_LIBS ${ARGN})
			string(REPLACE ".lib" ".dll" DEP_LIBS_DLL "${DEP_LIBS}")
		else()
			get_target_property(DEP_LIBS ${DEP_TARGET_NAME} IMPORTED_LOCATION)
			# this should already be correct if IMPORTED_LOCATION was set properly, but just in case...
			string(REPLACE ".lib" ".dll" DEP_LIBS_DLL "${DEP_LIBS}")
			# Check if the target has dependencies of its own to copy over. This could recursively check dependencies of dependencies but there's currently no use-case.
			get_target_property(_DEP_AUX_LIBS ${DEP_TARGET_NAME} IMPORTED_LINK_DEPENDENT_LIBRARIES)
			if(_DEP_AUX_LIBS)
				list(APPEND DEP_AUX_LIBS ${_DEP_AUX_LIBS})
			endif()
			get_target_property(_DEP_AUX_LIBS ${DEP_TARGET_NAME} INTERFACE_LINK_LIBRARIES)
			if(_DEP_AUX_LIBS)
				list(APPEND DEP_AUX_LIBS ${_DEP_AUX_LIBS})
			endif()
			if(DEP_AUX_LIBS)
				list(REMOVE_DUPLICATES DEP_AUX_LIBS)
			endif()
			string(REPLACE "${CMAKE_STATIC_LIBRARY_SUFFIX}" "${CMAKE_SHARED_LIBRARY_SUFFIX}" DEP_AUX_LIBS_DLL "${DEP_AUX_LIBS}")
			foreach(lib ${DEP_AUX_LIBS_DLL})
				if(EXISTS ${lib})
					list(APPEND DEP_LIBS_DLL ${lib})
				endif()
			endforeach()
		endif()
		# Copy over dependency libraries into LibraryResources/$SystemID
		detect_system_id(SYSTEMID)
		install(FILES
				${DEP_LIBS_DLL}
				DESTINATION ${PACLET_NAME}/LibraryResources/${SYSTEMID}
				)
	endif()
endfunction()

# Sets default CXX properties and ensures stdc++_nonshared is linked on Linux (needed for RedHat if using >= c++11).
function(set_default_cxx_properties TARGET_NAME CXX_STD)
	set_target_properties(${TARGET_NAME} PROPERTIES
			CXX_STANDARD ${CXX_STD}
			CXX_STANDARD_REQUIRED YES
			CXX_EXTENSIONS NO
			CXX_VISIBILITY_PRESET hidden
			)
	add_cpp_nonshared_library(${TARGET_NAME})
endfunction()

# Sets default paclet compile options for warning and debugging/optimization. On Windows, also sets /EHsc.
function(set_default_compile_options TARGET_NAME OPTIMIZATION_LEVEL)
	string(REGEX REPLACE "[/-]?(.+)" "\\1" _OPTIMIZATION_LEVEL "${OPTIMIZATION_LEVEL}")
	if(MSVC)
		target_compile_options(${TARGET_NAME} PRIVATE
				"/W4"
				"$<$<CONFIG:Debug>:/Zi>"
				"$<$<CONFIG:Release>:/${_OPTIMIZATION_LEVEL}>"
				"/EHsc"
				)
	else()
		target_compile_options(${TARGET_NAME} PRIVATE
				"-Wall"
				"-Wextra"
				"-pedantic"
				"$<$<CONFIG:Release>:-${_OPTIMIZATION_LEVEL}>"
				)
	endif()
endfunction()

# Forces static runtime on Windows. See https://gitlab.kitware.com/cmake/community/wikis/FAQ#dynamic-replace
macro(set_windows_static_runtime)
	if(WIN32)
		foreach(flag_var CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
			if(${flag_var} MATCHES "/MD")
				string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
			endif()
		endforeach()
	endif()
endmacro()

# Adds compile definitions to the specified target to set minimum Windows version.
# Macro values are described here: https://docs.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt
function(set_min_windows_version TARGET_NAME VER)
	if(WIN32)
		if(${VER} STREQUAL 7)
			set(_VER 0x0601) # support at least Windows 7
		elseif(${VER} STREQUAL 8)
			set(_VER 0x0602) # support at least Windows 8
		elseif(${VER} STREQUAL 8.1)
			set(_VER 0x0603) # support at least Windows 8.1
		elseif(${VER} STREQUAL 10)
			set(_VER 0x0A00) # support at least Windows 10
		elseif(${VER} MATCHES "0x[0-9A-Fa-f]+")
			set(_VER ${VER})
		else()
			message(FATAL_ERROR "Unrecognized Windows version: ${VER}")
		endif()
		target_compile_definitions(${TARGET_NAME} PRIVATE
				WINVER=${_VER}
				_WIN32_WINNT=${_VER}
				)
	endif()
endfunction()

# Appends a list of frameworks to linker options and ensures headerpad_max_install_names is set.
function(add_frameworks TARGET_NAME)
	foreach(framework ${ARGN})
		list(APPEND FRAMEWORKS "-framework ${framework}")
	endforeach()
	target_link_libraries(${TARGET_NAME} PRIVATE
			${FRAMEWORKS}
			"-headerpad_max_install_names"
			)
endfunction()

# Checks if variable VAR is set either as a regular or an environment variable and if so, sets variable RES.
function(set_from_env VAR RES)
	if(${VAR})
		set(${RES} "${${VAR}}" PARENT_SCOPE)
	elseif(DEFINED ENV{${VAR}})
		set(${RES} "$ENV{${VAR}}" PARENT_SCOPE)
	endif()
endfunction()

# Sets search paths for library headers and binaries from system locations for use in Find modules.
# The paths are stored in (uppercase) LIBNAME_INC_SEARCH_DIR and LIBNAME_LIB_SEARCH_DIR, respectively.
function(set_system_library_search_paths_linuxarm LIBNAME)
	detect_system_id(SYSTEMID)
	if("${SYSTEMID}" STREQUAL "Linux-ARM")
		string(TOUPPER ${LIBNAME} uLIBNAME)
		if(NOT ${uLIBNAME}_INC_SEARCH_DIR)
			set(${uLIBNAME}_INC_SEARCH_DIR "/usr/include" PARENT_SCOPE)
		endif()
		if(NOT ${uLIBNAME}_LIB_SEARCH_DIR)
			set(${uLIBNAME}_LIB_SEARCH_DIR "/usr/lib/arm-linux-gnueabihf" PARENT_SCOPE)
		endif()
	endif()
endfunction()

# Sets search paths for LIBNAME to pass to find_path and find_library based on the presence of variables
# LIBNAME_DIR, LIBNAME_INC_SEARCH_DIR and LIBNAME_LIB_SEARCH_DIR (cf set_system_library_search_paths_linuxarm)
function(get_library_search_paths LIBNAME INC_PATH LIB_PATH)
	# Check if LIBNAME_DIR is set as a regular or environment variable
	set_from_env(${LIBNAME}_DIR _DEFAULT_SEARCH_DIR)
	# Check if custom include path has been set to override LIBNAME_DIR
	if(${LIBNAME}_INC_SEARCH_DIR)
		set(${INC_PATH} ${${LIBNAME}_INC_SEARCH_DIR} PARENT_SCOPE)
	elseif(_DEFAULT_SEARCH_DIR)
		set(${INC_PATH} ${_DEFAULT_SEARCH_DIR} PARENT_SCOPE)
	endif()
	# Check if custom library path has been set to override LIBNAME_DIR
	if(${LIBNAME}_LIB_SEARCH_DIR)
		set(${LIB_PATH} ${${LIBNAME}_LIB_SEARCH_DIR} PARENT_SCOPE)
	elseif(_DEFAULT_SEARCH_DIR)
		set(${LIB_PATH} ${_DEFAULT_SEARCH_DIR} PARENT_SCOPE)
	endif()
endfunction()

# Appends a cmake definition to a list of options OPTS only if VAR is set.
macro(append_def OPTS VAR)
	if(${VAR})
		list(APPEND ${OPTS} "-D${VAR}=${${VAR}}")
	endif()
endmacro()

# Appends a cmake flag to a list of options OPTS only if VAR is set.
macro(append_opt OPTS FLAG VAR)
	if(${VAR})
		list(APPEND ${OPTS} ${FLAG} "${${VAR}}")
	endif()
endmacro()

# Aborts cmake if the given string file or directory does not exist.
macro(fail_if_dne FILE_OR_DIR)
	if(NOT EXISTS "${FILE_OR_DIR}")
		if(${ARGC} GREATER 1)
			message(FATAL_ERROR "${ARGV1}")
		else()
			message(FATAL_ERROR "File or directory does not exist: ${FILE_OR_DIR}")
		endif()
	endif()
endmacro()
