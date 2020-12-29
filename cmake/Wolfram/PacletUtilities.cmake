# Wolfram/PacletUtilities.cmake
#
# A set of tools for installing files into proper Wolfram Language paclets.
#

macro(set_if_undefined VAR VALUE)
	if(NOT ${VAR})
		set(${VAR} ${VALUE})
	endif()
endmacro()

macro(required_arg VAR MESSAGE)
	if(NOT ${VAR})
		message(FATAL_ERROR ${MESSAGE})
	endif()
endmacro()

macro(find_paclet_info DIR PACLET_INFO_LOCATION)
	find_file(${PACLET_INFO_LOCATION}
			NAMES PacletInfo.wl PacletInfo.wl.in PacletInfo.m PacletInfo.m.in
			HINTS ${DIR}
			DOC "Path to the PacletInfo file"
			NO_DEFAULT_PATH)
endmacro()

# Copies paclet files to install location (CMAKE_INSTALL_PREFIX should be set appropriately before calling this).
# Optional 3rd arg is PacletName (defaults to TARGET_NAME). Optional 4th arg is paclet location (defaults to CMAKE_CURRENT_SOURCE_DIR/PacletName).
# "Old-style" (non-updateable) paclet layout (with PacletInfo.m in git root directory) is not supported.
function(install_paclet_files)
	set(OPTIONS INSTALL_TO_LAYOUT)
	set(ONE_VALUE_ARGS TARGET LLU_LOCATION PACLET_NAME PACLET_FILES_LOCATION)
	set(MULTI_VALUE_ARGS)
	cmake_parse_arguments(INSTALL_PACLET "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN})

	required_arg(INSTALL_PACLET_TARGET "Target must be specified.")
	set_if_undefined(INSTALL_PACLET_PACLET_NAME ${INSTALL_PACLET_TARGET})
	set_if_undefined(INSTALL_PACLET_PACLET_FILES_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/${INSTALL_PACLET_PACLET_NAME})

	find_paclet_info(${INSTALL_PACLET_PACLET_FILES_LOCATION} PACLET_INFO)
	if(NOT PACLET_INFO)
		message(WARNING "PacletInfo file could not be found. Paclet might be broken.")
	else()
		configure_file(${PACLET_INFO} ${CMAKE_CURRENT_BINARY_DIR}/PacletInfo.wl @ONLY) # enforce modern .wl extension
	endif()

	#copy over the paclet directory - i.e. .wl sources and other files except PacletInfo
	install(DIRECTORY ${INSTALL_PACLET_PACLET_FILES_LOCATION}
			DESTINATION ${CMAKE_INSTALL_PREFIX}
			PATTERN ".DS_Store" EXCLUDE
			PATTERN REGEX ${PACLET_INFO} EXCLUDE)

	# install generated PacletInfo
	install(FILES ${CMAKE_CURRENT_BINARY_DIR}/PacletInfo.wl
			DESTINATION ${CMAKE_INSTALL_PREFIX}/${INSTALL_PACLET_PACLET_NAME})

	#copy the library produced into LibraryResources/$SystemID
	set(LIB_RESOURCES_DIR "${INSTALL_PACLET_PACLET_NAME}/LibraryResources")
	detect_system_id(SYSTEMID)
	install(TARGETS ${INSTALL_PACLET_TARGET}
			LIBRARY DESTINATION ${LIB_RESOURCES_DIR}/${SYSTEMID}
			RUNTIME DESTINATION ${LIB_RESOURCES_DIR}/${SYSTEMID}
			)

	# copy LLU top-level code
	if(NOT INSTALL_PACLET_LLU_LOCATION)
		message(WARNING "*** LLU_LOCATION was not specified. This may be OK if the paclet is not using LLU. ***")
	else()
		install(FILES "${INSTALL_PACLET_LLU_LOCATION}/share/LibraryLinkUtilities.wl"
				DESTINATION ${LIB_RESOURCES_DIR}
				)
	endif()

	if(INSTALL_PACLET_INSTALL_TO_LAYOUT)
		install_paclet_to_layout(${INSTALL_PACLET_PACLET_NAME} TRUE)
	endif()
endfunction()

# Installs paclet into a Wolfram product layout if requested.
macro(install_paclet_to_layout PACLET_NAME INSTALLQ)
	if(${INSTALLQ})
		if(EXISTS "${WolframLanguage_INSTALL_DIR}")
			install(DIRECTORY "${CMAKE_INSTALL_PREFIX}/${PACLET_NAME}"
					DESTINATION "${WolframLanguage_INSTALL_DIR}/SystemFiles/Links"
					)
		else()
			message(WARNING "Failed to install paclet to layout: \"${WolframLanguage_INSTALL_DIR}\" does not exist.")
		endif()
	endif()
endmacro()

# Creates a custom 'zip' target for a paclet.
# CMAKE_INSTALL_PREFIX should be set appropriately before calling this.
function(create_zip_target PACLET_NAME)
	message(DEPRECATION "Distributing paclets in .zip archives is deprecated in favor of .paclet format. Consider using pack_paclet() function instead.")
	add_custom_target(zip
			COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${CMAKE_INSTALL_PREFIX}/${PACLET_NAME}.zip" --format=zip "${CMAKE_INSTALL_PREFIX}/${PACLET_NAME}"
			COMMENT "Creating zip..."
			)
endfunction()

# Create a target that produces a proper .paclet file for the project. It takes a paclet layout, packs it into a .paclet file, optionally verifies
# contents, installs to the user paclet directory and run tests. A sample call may look like this:
#
#   add_paclet_target(paclet        # target name, can be anything [required]
#       NAME Demo                   # paclet name [required]
#       VERIFY                      # verify contents of the .paclet file [optional]
#       INSTALL                     # install to the user paclet directory [optional]
#       TEST_FILE Tests/test.wl     # run tests if the paclet has any [optional]
#   )
#
# For this function to work, install target must be built beforehand and wolframscript from WolframLanguage v12.1 or later must be available.
function(add_paclet_target TARGET_NAME)
	set(OPTIONS VERIFY INSTALL)
	set(ONE_VALUE_ARGS NAME TEST_FILE)
	set(MULTI_VALUE_ARGS)
	cmake_parse_arguments(MAKE_PACLET "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN})
	required_arg(MAKE_PACLET_NAME "Paclet name must be provided.")

	unset(WolframLanguage_FOUND)
	find_package(WolframLanguage 12.1 QUIET COMPONENTS wolframscript)
	if (NOT WolframLanguage_FOUND OR NOT WolframLanguage_wolframscript_EXE)
		message(WARNING "Could not find wolframscript 12.1 or higher. \"paclet\" target will not be created.")
		return()
	endif()

	if(MAKE_PACLET_VERIFY)
		set(VERIFICATION_MESSAGE " and verifying PacletInfo contents")
	endif()

	if(MAKE_PACLET_TEST_FILE)
		set(RUN_TESTS TRUE)
		get_filename_component(TEST_FILE ${MAKE_PACLET_TEST_FILE} ABSOLUTE BASE_DIR ${CMAKE_CURRENT_LIST_DIR})
		if(NOT EXISTS ${TEST_FILE})
			message(WARNING "Test file ${TEST_FILE} does not exist. Skipping tests.")
			set(RUN_TESTS FALSE)
		endif()
	endif()

	set(WL_CODE
			[===[
			SetOptions[$Output, FormatType -> OutputForm];
			pacDir = "${MAKE_PACLET_NAME}";
			If[Not @ DirectoryQ[pacDir],
				Print @ StringJoin @ {"Paclet directory \"", pacDir, "\" does not exist. Make sure you ran the install target."};
				Exit[1]
			];
			paclet = CreatePacletArchive[pacDir];
			If[FailureQ[paclet],
				Print["ERROR: Could not create paclet."];
				Exit[1]
				,
				Print["Paclet successfully created:"];
				Print @ Column[("\t" <> First[#] -> Last[#]) & /@ (DeleteMissing @ PacletObject[paclet][All])]
			];
			If["${MAKE_PACLET_VERIFY}" === "TRUE",
				If[Not @ PacletManager`VerifyPaclet[paclet],
					Print["ERROR: Paclet verification failed! Check the structure of your project and the contents of PacletInfo file."];
					Exit[1]
				];
				hasLLExt = MemberQ[First[PacletObject[paclet]]["Extensions"], {"LibraryLink", ___}];
				If[Not @ hasLLExt,
					Print["WARNING: Paclet does not contain the \"LibraryLink\" extension which may potentially lead to loading issues."];
				];
				Print["Paclet verified."];
			];
			If["${MAKE_PACLET_INSTALL}" === "TRUE",
				If[PacletObjectQ[p = PacletInstall[paclet, ForceVersionInstall -> True]],
					Print["Paclet installed to " <> p["Location"]]
					,
					Print["ERROR: Paclet installation failed."]
					Exit[1]
				]
			];
			If["${RUN_TESTS}" === "TRUE",
				Print["Running test file ${TEST_FILE}"];
				Get["${TEST_FILE}"]
			];
			Exit[0]
			]===])

	string(REGEX REPLACE "[\t\r\n]+" "" WL_CODE "${WL_CODE}")
	string(CONFIGURE "${WL_CODE}" WL_CODE)

	add_custom_target(${TARGET_NAME}
			COMMAND ${WolframLanguage_wolframscript_EXE} -code "${WL_CODE}"
			WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}
			COMMENT "Creating .paclet file${VERIFICATION_MESSAGE}..."
			VERBATIM
			)
endfunction()