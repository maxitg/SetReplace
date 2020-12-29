# FindSphinx.cmake
#
# Simple module that finds Sphinx executable, does not check version
#
# This will define the following variables
#
#    SPHINX_FOUND
#    SPHINX_EXECUTABLE
#
# You can specify custom location to search for Sphinx by specifying SPHINX_EXE_PATH either as regular or environment variable
#
# Author: Rafal Chojna - rafalc@wolfram.com

if (SPHINX_EXE_PATH)
    set(_SPHINX_EXE_PATH "${SPHINX_EXE_PATH}")
elseif ($ENV{SPHINX_EXE_PATH})
    set(_SPHINX_EXE_PATH "$ENV{SPHINX_EXE_PATH}")
endif ()

if (_SPHINX_EXE_PATH)
    set(_SPHINX_SEARCH_OPTS NO_DEFAULT_PATH)
else ()
    set(_SPHINX_SEARCH_OPTS)
endif ()

# Find Sphinx. The executable is called sphinx-build
find_program(SPHINX_EXECUTABLE
        NAMES sphinx-build
        PATHS ${_SPHINX_EXE_PATH}
        ${_SPHINX_SEARCH_OPTS}
        DOC "Path to sphinx-build executable")


# Let FindPackageHandleStandardArgs do the rest
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Sphinx DEFAULT_MSG SPHINX_EXECUTABLE)
