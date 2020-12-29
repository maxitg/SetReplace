################################################################################
######
###### LLU Demo Project Configuration File
######
################################################################################

cmake_minimum_required(VERSION 3.14.0)

project(Demo
		VERSION     0.0.1
		DESCRIPTION "Demo paclet that shows how to use LibraryLinkUtilities."
		LANGUAGES   CXX
)

# By default install to the build directory
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Demo paclet install prefix" FORCE)
endif ()

#=============================================
#=============== FIND LLU ====================
#=============================================

set(LLU_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../install" CACHE PATH "Location of LLU installation.")

find_package(LLU 3.0.1 EXACT REQUIRED NO_MODULE PATH_SUFFIXES LLU)

#=============================================
#=========== MAIN PACLET LIBRARY =============
#=============================================

# define source files
set(DEMO_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/Sources/)
set(DEMO_SOURCE_FILES ${DEMO_SOURCE_DIR}/demo.cpp)

#add the main library
add_library(Demo SHARED ${DEMO_SOURCE_FILES})

#in paclets we usually skip the "lib" prefix to get the same library name on all platforms
set_property(TARGET Demo PROPERTY PREFIX "")

set_target_properties(Demo PROPERTIES
		CXX_STANDARD 17
		CXX_STANDARD_REQUIRED YES
		CXX_EXTENSIONS NO
		CXX_VISIBILITY_PRESET hidden
)

# set compile options
# here we use a utility function from cmake/Wolfram/Common.cmake which sets a basic set of compiler flags in a cross-platform way
set_default_compile_options(Demo O2)

# We need to link statically to runtime library on Windows because this is how LLU is built, on other platforms this command is a no-op
set_windows_static_runtime()

# link to LLU
target_link_libraries(Demo PRIVATE LLU::LLU)

#=============================================
#=========== INSTALL PACLET ==================
#=============================================

# run the install target to create a complete paclet directory structure, this will not create a .paclet file
# LLU_LOCATION is required for this step because we need to copy LibraryLinkUtilities.wl file to the paclet files
install_paclet_files(
		TARGET Demo
		LLU_LOCATION ${LLU_ROOT}
#		INSTALL_TO_LAYOUT  <- uncomment to have CMake install all paclet files to the SystemFiles/Links directory of your Mathematica installation
)

# Create a CMake target called "paclet" which will take the directory structure created by the "install" target and turn it into a proper .paclet file.
# It can optionally validate paclet contents, run a test file or install paclet to a directory where Mathematica can automatically find it.
# Requires Mathematica 12.1+.
add_paclet_target(paclet            # target name
		NAME Demo                   # paclet name
		VERIFY                      # verify contents of the .paclet file
		INSTALL                     # install to the user paclet directory
		TEST_FILE Tests/test.wl     # run tests (test.wl may contain arbitrary WL code, not necessarily MUnit` tests)
)