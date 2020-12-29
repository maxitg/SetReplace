================================
CMake utility functions
================================

Apart from the C++ and Wolfram Language APIs, LLU offers a range of CMake utility functions to automate common steps in building LibraryLink paclets with CMake.
While it is not at all required to use CMake in a project that links to LLU, it is definitely convenient, as LLU is specifically tailored to be used
by other CMake projects.

When you install LLU, a :file:`cmake` directory is created in the installation directory, with the following contents:

.. code-block:: none
   :emphasize-lines: 5,7

   .
   └── cmake
       └── LLU
           ├── Wolfram
           │   ├── Common.cmake
           │   ├── CVSUtilities.cmake
           │   └── PacletUtilities.cmake
           ├── FindWolframLanguage.cmake
           ├── FindWolframLibrary.cmake
           ├── FindWSTP.cmake
           ├── LLUConfig.cmake
           ├── LLUConfigVersion.cmake
           └── LLUTargets.cmake

Most of these files are used internally by LLU or by CMake in order to get information about LLU installation when you link to it from your project.
However, in the :file:`Wolfram` subdirectory you will find two files (highlighted) with general purpose utilities which are documented below.

.. tip::

   Check out the :ref:`Demo paclet <demo-project>` to see how some of these utilities can be used in a project.

Common
================================

:file:`cmake/LLU/Wolfram/Common.cmake` contains a number of small CMake functions and macros that automate common tasks when writing cross-platform CMake code.
Not all of them will be useful in every project so feel free to choose whatever suits your needs.

.. cmake:command:: set_machine_flags

   **Syntax:**

   .. code-block:: cmake

      set_machine_flags(<target>)

   Depending on the machine architecture and operating system this function sets correct "machine flag" for given target:

   - on Windows it sets ``/MACHINE:XX`` link flag
   - on Linux and MacOS it sets ``-mXX`` flag for compilation and linking

   Additionally, on 32-bit platforms it also defines ``MINT_32`` macro to indicate to the Wolfram Library to use 32-bit machine integers.


.. cmake:command:: set_windows_static_runtime

   **Syntax:**

   .. code-block:: cmake

      set_windows_static_runtime()

   Forces static runtime on Windows and does nothing on other platforms. See https://gitlab.kitware.com/cmake/community/wikis/FAQ#dynamic-replace for details.


.. cmake:command:: set_min_windows_version

   **Syntax:**

   .. code-block:: cmake

      set_min_windows_version(<target> <version>)

   Adds compile definitions to the specified target to set minimum supported Windows version. Does nothing on other platforms.
   Supported values of ``<version>`` include: 7, 8, 8.1 and 10.


.. cmake:command:: set_default_compile_options

   **Syntax:**

   .. code-block:: cmake

      set_default_compile_options(<target> <optimization>)

   Sets default paclet compile options including warning level and optimization. On Windows, also sets ``/EHsc``. A call to this function may be used
   as a starting point and new compile options can be added with consecutive calls to :cmake:command:`target_compile_options`.


.. cmake:command:: install_dependency_files

   **Syntax:**

   .. code-block:: cmake

      install_dependency_files(<paclet_name> <dependency_target> [lib1, lib2, ...])

   Copies dependency libraries into paclet layout if the library type is SHARED (always copies on Windows).
   Optional arguments are the libraries to copy (defaults to main target file plus its dependencies).

   **Arguments:**

   :cmake:variable:`<paclet_name>`
      name of the paclet (i.e. name of the paclet's layout root directory)
   :cmake:variable:`<dependency_target>`
      CMake target corresponding to a dependency of the paclet
   :cmake:variable:`lib1, lib2, ...`
      *[optional]* absolute paths to dynamic libraries on which the paclet depends and which should be copied to the paclet's layout. If not provided,
      this information will be deduces from the ``<dependency_target>``.

Paclet Utilities
================================

:file:`cmake/LLU/Wolfram/PacletUtilities.cmake` contains CMake functions for installing and packaging projects into proper :term:`paclet`\ s.

.. cmake:command:: install_paclet_files

	**Syntax:**

	.. code-block:: cmake

		install_paclet_files(
			TARGET <target>
			[LLU_LOCATION path]
			[PACLET_NAME name]
			[PACLET_FILES_LOCATION path2]
			[INSTALL_TO_LAYOUT])

	Configures the CMake *install* target for a paclet. The only required argument is :cmake:variable:`TARGET` which should be followed by the main paclet
	target (that defines the shared library). The *install* target configured with this function will copy the directory
	passed as :cmake:variable:`PACLET_FILES_LOCATION` into the location stored in :cmake:variable:`CMAKE_INSTALL_PREFIX`. It will also place the
	:file:`PacletInfo.wl` in the appropriate location in the paclet and put the shared library under :file:`LibraryResources/<system_id>`.

	**Arguments:**

	:cmake:variable:`TARGET`
		name of the main target in the paclet's CMakeLists.txt
	:cmake:variable:`LLU_LOCATION`
		path to LLU installation. This is needed because every paclet that uses the Wolfram Language part of the LLU API needs a copy of
		:file:`LibraryLinkUtilities.wl` which is stored in the :file:`share` folder of LLU installation.
	:cmake:variable:`PACLET_NAME`
		*[optional]* if the name of the paclet is different than the name of the main paclet target, pass it here
	:cmake:variable:`PACLET_FILES_LOCATION`
		*[optional]* location of the Wolfram Language source files in the paclet, by default it is assumed as ``${CMAKE_CURRENT_SOURCE_DIR}/PACLET_NAME``
	:cmake:variable:`INSTALL_TO_LAYOUT`
		*[optional]* a flag indicating whether the complete paclet layout (what the *install* target produces) should be also copied to the :file:`SystemFiles/Links`
		directory of current Wolfram Language installation (the one used for paclet configuration)

----------------------------------------

.. cmake:command:: add_paclet_target

	**Syntax:**

	.. code-block:: cmake

		add_paclet_target(<target>
			NAME name
			[VERIFY]
			[INSTALL]
			[TEST_FILE file]
		)

	Create a target that produces a proper .paclet file for the project. It takes a paclet layout, produced by the *install* target, packs it into a .paclet
	file, optionally verifies contents, installs to the user paclet directory and run tests.

	.. warning::
		For this function to work, *install* target must be built beforehand and wolframscript from Wolfram Language v12.1 or later must be available.

	**Arguments:**

	``<target>``
		name for the new target, can be anything
	:cmake:variable:`NAME`
		name of the paclet, it must match the name of the paclet's layout root directory
	:cmake:variable:`VERIFY`
		*[optional]* verify contents of the newly created .paclet file
	:cmake:variable:`INSTALL`
		*[optional]* install .paclet file to the user paclet directory, see :wlref:`PacletInstall` for details
	:cmake:variable:`TEST_FILE`
		*[optional]* provide a path to a test file, if your paclet has one. There is no magic here, CMake will simply ask wolframscript to evaluate the file
		you provided. What will actually happen fully depends on the contents of your test file.

