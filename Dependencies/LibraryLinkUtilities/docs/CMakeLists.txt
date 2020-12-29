find_package(Doxygen 1.8.15 REQUIRED OPTIONAL_COMPONENTS dot)

set(DOCUMENTATION_SOURCE ${CMAKE_CURRENT_SOURCE_DIR})

# Set the location for generated doxygen documentation
set(DOXYGEN_OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/doxy)

# Additional doxygen options
set(DOXYGEN_GENERATE_HTML NO)
set(DOXYGEN_GENERATE_XML YES)
set(DOXYGEN_GENERATE_LATEX NO)

# First we go through LibraryLinkUtilities.doxyfile.in substituting only @XXX@ tags which provide basic info like LLU version and description,
# but this step still leaves ${XXX} tags in the doxyfile which can be substituted by different tool for custom styling. That is why we create an intermediate
# doxyfile in this step.
set(INTERMEDIATE_DOXYFILE "${DOXYGEN_OUTPUT_DIR}/LibraryLinkUtilities.doxyfile.intermediate")
configure_file(
		"${DOCUMENTATION_SOURCE}/LibraryLinkUtilities.doxyfile.in"
		${INTERMEDIATE_DOXYFILE}
		@ONLY)

# In the next step we replace remaining ${XXXX} in the intermediate doxyfile.
set(GENERATED_DOXYFILE "${DOXYGEN_OUTPUT_DIR}/LibraryLinkUtilities.doxyfile")
configure_file(
	"${DOXYGEN_OUTPUT_DIR}/LibraryLinkUtilities.doxyfile.intermediate"
	${GENERATED_DOXYFILE})

# Doxygen generation output
set(DOXYGEN_OUTPUT_INDEX ${DOXYGEN_OUTPUT_DIR}/xml/index.xml)

# Custom command that when run will actually generate the documentation
add_custom_command(
		OUTPUT ${DOXYGEN_OUTPUT_INDEX}
		# Generate doxygen documentation
		COMMAND Doxygen::doxygen ${GENERATED_DOXYFILE}
		# We need to work where the original doxyfile resides because source paths in doxyfiles are often relative
		WORKING_DIRECTORY ${DOCUMENTATION_SOURCE}
		COMMENT "Generating documentation with Doxygen"
		VERBATIM)

# Custom target for generating documentation
add_custom_target(doxygen DEPENDS ${DOXYGEN_OUTPUT_INDEX})

# Helper macro for locating dependencies for Breathe+Sphinx documentation build. If they are missing we just return and create only the "doxygen" target.
macro(find_or_exit DEPENDENCY)
	find_package(${DEPENDENCY})
	if(NOT ${DEPENDENCY}_FOUND)
		message(WARNING "Could not find ${DEPENDENCY}. You will not be able to generate Breathe+Sphinx documentation but you can still generate Doxygen.")
		return()
	endif()
endmacro()

find_or_exit(Python)
find_or_exit(Sphinx)
find_or_exit(Breathe)

# Determine Sphinx theme for the docs. Use the following variables:
#   SPHINX_THEME - this should be one of the built-in Sphinx themes, see https://www.sphinx-doc.org/en/master/usage/theming.html
#   SPHINX_CUSTOM_THEME - if you don't want a built-in theme, use custom one that you have installed, this takes precedence over SPHINX_THEME
# When you use a custom theme, you will also need to specify SPHINX_THEME_PATH and possibly SPHINX_CUSTOM_THEME_INIT which allow Sphinx to find your theme.
# For example, imagine I want to use a neo_rtd_theme from https://github.com/LinxiFan/Sphinx-theme. To do this, I need to pass:
#   -DSPHINX_CUSTOM_THEME=neo_rtd_theme
#   -DSPHINX_CUSTOM_THEME_INIT="import sphinx_theme"
#   -DSPHINX_THEME_PATH="sphinx_theme.get_html_theme_path('neo_rtd_theme')"
# The default theme is "bizstyle" from built-in Sphinx themes.
if (SPHINX_CUSTOM_THEME)
	set(SPHINX_THEME ${SPHINX_CUSTOM_THEME})
elseif(NOT SPHINX_THEME)
	set(SPHINX_THEME bizstyle)
endif()

# Go through conf.py.in substituting custom values
set(SPHINX_CONF_DIR ${DOCUMENTATION_SOURCE})
configure_file(
		"${SPHINX_CONF_DIR}/conf.py.in"
		"${CMAKE_CURRENT_BINARY_DIR}/conf.py"
		@ONLY)

# Set the location for the generated Sphinx docs
set(SPHINX_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/LLU)

# Create a target that runs Breathe and Sphinx on the doxygen output. This depends on the doxygen target.
add_custom_target(
		docs
		DEPENDS
			${DOXYGEN_OUTPUT_INDEX}
		COMMAND
			${SPHINX_EXECUTABLE}
				-q
				-b html
				-c ${CMAKE_CURRENT_BINARY_DIR}
				-j auto
				${DOCUMENTATION_SOURCE}
				${SPHINX_OUTPUT}
		WORKING_DIRECTORY
			${DOCUMENTATION_SOURCE}
		COMMENT
			"Generating HTML documentation with Doxygen + Breathe + Sphinx"
		VERBATIM)
