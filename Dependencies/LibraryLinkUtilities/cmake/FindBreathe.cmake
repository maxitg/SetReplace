# FindBreathe.cmake
#
# Simple module that finds a Python module called Breathe. It assumes that Python interpreter is available.
#
# This will define the following variables
#
#    BREATHE_FOUND
#    BREATHE_MODULE_LOCATION
#
# You can skip the search by providing BREATHE_MODULE_LOCATION manually

# Find the Breathe module
if (NOT BREATHE_MODULE_LOCATION)
    execute_process(
        COMMAND "${Python_EXECUTABLE}" "-c"
        "from __future__ import print_function; import re, breathe; print(re.compile('/__init__.py.*').sub('', breathe.__file__))"
        RESULT_VARIABLE _BREATHE_STATUS
        OUTPUT_VARIABLE _BREATHE_LOCATION
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if (NOT _BREATHE_STATUS)
        set(BREATHE_MODULE_LOCATION ${_BREATHE_LOCATION} CACHE STRING "Location of Breathe")
        mark_as_advanced(BREATHE_MODULE_LOCATION)
    endif ()
endif ()

# Let FindPackageHandleStandardArgs do the rest
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Breathe DEFAULT_MSG BREATHE_MODULE_LOCATION)