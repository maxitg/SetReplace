// Library definition for Wolfram LibraryLink

#ifndef LIBSETREPLACE_WOLFRAMLANGUAGEAPI_HPP_
#define LIBSETREPLACE_WOLFRAMLANGUAGEAPI_HPP_

#include "WolframHeaders/WolframLibrary.h"

EXTERN_C DLLEXPORT mint WolframLibrary_getVersion();

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData);

EXTERN_C DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData);

/** @brief Creates a new hypergraph substitution system.
 */
EXTERN_C DLLEXPORT int hypergraphSubstitutionSystemInitialize(WolframLibraryData libData,
                                                              mint argc,
                                                              MArgument* argv,
                                                              MArgument result);

/** @brief Performs a specified number of replacements, but does not return anything.
 */
EXTERN_C DLLEXPORT int hypergraphSubstitutionSystemReplace(WolframLibraryData libData,
                                                           mint argc,
                                                           MArgument* argv,
                                                           MArgument result);

/** @brief Returns a list of tokens for a specified hypergraph substitution system pointer.
 */
EXTERN_C DLLEXPORT int hypergraphSubstitutionSystemTokens(WolframLibraryData libData,
                                                          mint argc,
                                                          MArgument* argv,
                                                          MArgument result);

/** @brief Returns the list of events for a specified hypergraph substitution system pointer.
 */
EXTERN_C DLLEXPORT int hypergraphSubstitutionSystemEvents(WolframLibraryData libData,
                                                          mint argc,
                                                          MArgument* argv,
                                                          MArgument result);

/** @brief Returns the largest generation that has both been reached, and has no matches that would produce tokens
 * with that or lower generation.
 * @details Is abortable, in which case returns LIBRARY_FUNCTION_ERROR.
 */
EXTERN_C DLLEXPORT int hypergraphSubstitutionSystemMaxCompleteGeneration(WolframLibraryData libData,
                                                                         mint argc,
                                                                         MArgument* argv,
                                                                         MArgument result);

/** @brief Returns a number corresponding to the termination reason.
 */
EXTERN_C DLLEXPORT int hypergraphSubstitutionSystemTerminationReason(WolframLibraryData libData,
                                                                     mint argc,
                                                                     MArgument* argv,
                                                                     MArgument result);

#endif  // LIBSETREPLACE_WOLFRAMLANGUAGEAPI_HPP_
