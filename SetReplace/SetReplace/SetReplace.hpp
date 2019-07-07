// Library definition for Wolfram LibraryLink

#ifndef SetReplace_hpp
#define SetReplace_hpp

#include "WolframLibrary.h"

EXTERN_C DLLEXPORT mint WolframLibrary_getVersion();

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData);

EXTERN_C DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData);

EXTERN_C DLLEXPORT int setReplace(WolframLibraryData libData,
                                  mint argc,
                                  MArgument *argv,
                                  MArgument result);

#endif /* SetReplace_hpp */
