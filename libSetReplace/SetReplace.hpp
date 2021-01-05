// Library definition for Wolfram LibraryLink

#ifndef LIBSETREPLACE_SETREPLACE_HPP_
#define LIBSETREPLACE_SETREPLACE_HPP_

#include "WolframHeaders/WolframLibrary.h"

EXTERN_C DLLEXPORT mint WolframLibrary_getVersion();

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData);

EXTERN_C DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData);

/** @brief Creates a new set object.
 */
EXTERN_C DLLEXPORT int setInitialize(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result);

/** @brief Performs a specified number of replacements, but does not return anything.
 */
EXTERN_C DLLEXPORT int setReplace(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result);

/** @brief Returns a list of expressions for a specified set pointer.
 */
EXTERN_C DLLEXPORT int setExpressions(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result);

/** @brief Returns the list of events for a specified set pointer.
 */
EXTERN_C DLLEXPORT int setEvents(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result);

/** @brief Returns the largest generation that has both been reached, and has no matches that would produce expressions
 * with that or lower generation.
 * @details Is abortable, in which case returns LIBRARY_FUNCTION_ERROR.
 */
EXTERN_C DLLEXPORT int maxCompleteGeneration(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result);

/** @brief Returns a number corresponding to the termination reason.
 */
EXTERN_C DLLEXPORT int terminationReason(WolframLibraryData libData, mint argc, MArgument* argv, MArgument result);

#endif  // LIBSETREPLACE_SETREPLACE_HPP_
