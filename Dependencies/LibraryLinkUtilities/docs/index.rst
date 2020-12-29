.. include:: globals.rst

.. toctree::
   :hidden:
   :caption: Basic Info

   Intro <self>
   basic/how_to_use
   API reference (Doxygen ↪) <https://wolframresearch.github.io/LibraryLinkUtilities/doxygen/>
..   basic/faq

.. toctree::
   :hidden:
   :caption: Modules

   modules/functions
   modules/containers
   modules/error_handling
   modules/wstp
   modules/managed_expressions
   modules/logger
   modules/progress_monitor

.. toctree::
   :hidden:
   :caption: Other Notes

   other/paclet_use
   other/cmake_utilities


LibraryLink Utilities
=================================================

:dfn:`LibraryLink Utilities` (abbr. LLU) is an open-source library consisting of modern C++ wrappers over most parts of :term:`LibraryLink` -
the Wolfram Language framework for connecting to C and C++ libraries.
The official documentation including use instructions can be found here:

https://wolframresearch.github.io/LibraryLinkUtilities/

This documentation is split into modules. Each describes a core part of LLU providing general overview, examples and detailed description of related C++ entities.

Please use GitHub to report bugs, make suggestions and request features.

.. rst-class::  clear-both

Motivation
------------------------------

:term:`LibraryLink` is a great tool for connecting Wolfram Language to external C/C++ libraries and is widely used by Wolfram Research and
Wolfram Language developers for developing :term:`paclet`\ s.
:term:`LibraryLink Utilities` makes it even easier to use LibraryLink by providing features such as:

* automatic resource management
* exception handling
* container iterators
* class-like interface for data structures, for example ``rank()`` as member function of ``Tensor`` class instead of separate function ``mint MTensor_getRank(MTensor)``
* type safety
* lazy loading of library functions
* progress monitoring of library functions
* standardized approach to exchange custom data types between C++ and WL code

Example
----------------------------------

Let's demonstrate some advantages of :abbr:`LLU (LibraryLink Utilities)` by comparing the same function written with and without
:abbr:`LLU (LibraryLink Utilities)`.
Below we will implement a simple function ``repeatCharacters`` that takes a string ``s`` and a tensor ``t`` and returns a new string ``s2`` that consists of each
character ``s[i]`` from original string but repeated ``t[i]`` times. So, for example

.. code-block:: cpp

   repeatCharacters("abc", {3, 2, 1})

gives

.. parsed-literal::

   "aaabbc"

This is the C - style implementation:

.. code-block:: c
   :linenos:

   // global variable which is the buffer for strings returned to LibraryLink
   char* outString = NULL;

   EXTERN_C DLLEXPORT int repeatCharacters(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
      char* string = NULL;
      MNumericArray counts;
      uint8_t* countsData = NULL;
      size_t outStringIndex = 0;
      size_t len, j;
      mint sum = 0;
      mint c;

      string = MArgument_getUTF8String(Args[0]);
      counts = MArgument_getMNumericArray(Args[1]);

      // check NumericArray type
      if (libData->numericarrayLibraryFunctions->MNumericArray_getType(counts) != MNumericArray_Type_UBit8) {
         libData->UTF8String_disown(string);
         return LIBRARY_TYPE_ERROR;
      }

      // check NumericArray rank
      if (libData->numericarrayLibraryFunctions->MNumericArray_getRank(counts) != 1) {
         libData->UTF8String_disown(string);
         return LIBRARY_RANK_ERROR;
      }

      // check if NumericArray length is equal to input string length
      len = strlen(string);
      if (libData->numericarrayLibraryFunctions->MNumericArray_getFlattenedLength(counts) != len) {
         libData->UTF8String_disown(string);
         return LIBRARY_DIMENSION_ERROR;
      }

      // before we allocate memory for the output string, we have to sum all NumericArray elements
      // to see how many bytes are needed
      countsData = (uint8_t*) libData->numericarrayLibraryFunctions->MNumericArray_getData(counts);
      for (j = 0; j < len; j++) {
         sum += countsData[j];
      }

      // free memory owned by global buffer, if any (for example from the previous call to this function)
      free(outString);
      outString = NULL;

      // allocate memory for output string, outString has to be a global variable,
      // because it will be returned to LibraryLink
      outString = (char*) malloc(sum + 1);
      if (!outString) {
         libData->UTF8String_disown(string);
         return LIBRARY_FUNCTION_ERROR;
      }

      // populate output string
      for (j = 0; j < len; j++) {
         for (c = 0; c < countsData[j]; c++) {
            outString[outStringIndex++] = string[j];
         }
      }

      // add null terminator
      outString[sum] = '\0';

      // clean up and set result
      libData->UTF8String_disown(string);
      MArgument_setUTF8String(Res, outString);

      return LIBRARY_NO_ERROR;
   }


and this is the corresponding C++ version written with LibraryLink Utilities:

.. code-block:: cpp
   :linenos:

   EXTERN_C DLLEXPORT int repeatCharactersLLU(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
      auto err = LLU::ErrorCode::NoError;
      try {
         // Create manager object
         LLU::MArgumentManager mngr {libData, Argc, Args, Res};

         // Read string and NumericArray arguments
         auto string = mngr.getString(0);
         auto counts = mngr.getNumericArray<std::uint8_t>(1);

         // check NumericArray rank
         if (counts.rank() != 1) {
            LLU::ErrorManager::throwException(LLU::ErrorName::RankError);
         }

         // check if NumericArray length is equal to input string length
         if (counts.size() != string.size()) {
            LLU::ErrorManager::throwException(LLU::ErrorName::DimensionsError);
         }

         // before we allocate memory for the output string, we have to sum all NumericArray elements
         // to see how many bytes are needed
         auto sum = std::accumulate(std::cbegin(counts), std::cend(counts), static_cast<size_t>(0));

         // allocate memory for the output string
         std::string outString;
         outString.reserve(sum);

         // populate the output string
         for (mint i = 0; i < counts.size(); i++) {
            outString.append(std::string(counts[i], string[i]));
         }

         // clean up and set the result
         mngr.set(std::move(outString));
      } catch (const LLU::LibraryLinkError& e) {
         err = e.which();
      }
      return err;
   }

Limitations with respect to LibraryLink
---------------------------------------------

There are a few LibraryLink features currently not covered by LLU, most notably:

- Sparse Arrays
- Tensor subsetting: `MTensor_getTensor`
- Callbacks
- Wolfram IO Library (asynchronous tasks)


Glossary
================

.. glossary::

   LibraryLink
      The framework to connect external code to the Wolfram Language. See https://reference.wolfram.com/language/guide/LibraryLink.html

   LibraryLink Utilities
   LLU
      A set of modern C++ wrappers over different parts of :term:`LibraryLink`.

   library function
      A C/C++ function with special signature

      .. code-block:: cpp

         int f (WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res);

      or

      .. code-block:: cpp

         int f (WolframLibraryData libData, WSLINK mlp);

      Such functions can later be loaded into the Wolfram Language using :wlref:`LibraryFunctionLoad`.

   paclet
      A unit of the Wolfram Language functionality implemented in one or more files which can be auto-discovered, installed, loaded, etc. and must be
      accompanied by a **PacletInfo.wl** file.
      See the `official guide <https://reference.wolfram.com/language/guide/Paclets.html>`_ and even more in-depth
      `tutorial <https://www.wolframcloud.com/obj/tgayley/Published/PacletDevelopment.nb>`_ on paclet development.

   LibraryLink paclet
      A :term:`paclet` that has some of its functionality implemented in C or C++ using LibraryLink. Such paclets usually have a layer of the Wolfram Language
      code responsible at least for loading functions from the shared C/C++ library.

   LLU paclet
      A :term:`LibraryLink paclet` that additionally uses LibraryLink Utilities.

Contributors
==================

* Rafał Chojna (rafalc) - main developer
* Sean Cheren  (scheren) - top-level code for error handling, CMake improvements
* Rebecca Frederick (rebeccaf) - CMake improvements

