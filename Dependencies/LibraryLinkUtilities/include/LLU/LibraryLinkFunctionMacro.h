/**
 * @file	LibraryLinkFunctionMacro.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	10/08/2017
 *
 * @brief	Small collection of macros designed to reduce the amount of boilerplate code and to work around certain MSVC bug.
 * 			Defined in a separate header file to limit their scope.
 * 			Use those macros only for interface functions (functions that will be loaded with LibraryFunctionLoad).
 *
 * @see		https://stackoverflow.com/questions/45590594/generic-lambda-in-extern-c-function
 */

#ifndef LLU_LIBRARYLINKFUNCTIONMACRO_H
#define LLU_LIBRARYLINKFUNCTIONMACRO_H

/**
 * @brief   This macro forward declares and begins the definition of an extern "C" LibraryLink function with given name.
 * @details For input parameter and return type explanation see the official LibraryLink guide.
 * WolframLibraryData parameter is marked [[maybe_unused]] because it is a common workflow to take the instance of WolframLibraryData passed to
 * WolframLibrary_initialize function and store it with LLU::LibraryData::setLibraryData so that it is accessible everywhere.
 * With such setup one does not need to use the WolframLibraryData copy provided to every LibraryLink function.
 */
#define LIBRARY_LINK_FUNCTION(name)                                               \
	EXTERN_C DLLEXPORT int name(WolframLibraryData, mint, MArgument*, MArgument); \
	int name([[maybe_unused]] WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res)

/**
 * @brief   This macro forward declares and begins the definition of an extern "C" LibraryLink function with given name, which uses WSTP
 * to exchange data with WolframLanguage.
 * @copydetails LIBRARY_LINK_FUNCTION
 */
#define LIBRARY_WSTP_FUNCTION(name)                          \
	EXTERN_C DLLEXPORT int name(WolframLibraryData, WSLINK); \
	int name([[maybe_unused]] WolframLibraryData libData, WSLINK wsl)

/**
 * @brief   This macro provides all the boilerplate code needed for a typical exception-safe LibraryLink function.
 * @details LLU_LIBRARY_FUNCTION(MyFunction) defines a LibraryLink function MyFunction and a regular function impl_MyFunction of type
 * void(LLU::MArgumentManager&), which is the one you need to provide a body for. All LLU::LibraryLinkError exceptions thrown from impl_MyFunction will be
 * caught and the error code returned to LibraryLink. All other exceptions will also be caught and translated to a FunctionError.
 *
 * @note    While this macro saves quite a lot of typing it may also decrease code readability and make debugging harder so use with caution.
 */
#define LLU_LIBRARY_FUNCTION(name)                                      \
	void impl_##name(LLU::MArgumentManager&); /* forward declaration */ \
	LIBRARY_LINK_FUNCTION(name) {                                       \
		auto err = LLU::ErrorCode::NoError;                             \
		try {                                                           \
			LLU::MArgumentManager mngr {libData, Argc, Args, Res};      \
			impl_##name(mngr);                                          \
		} catch (const LLU::LibraryLinkError& e) {                      \
			err = e.which();                                            \
		} catch (...) {                                                 \
			err = LLU::ErrorCode::FunctionError;                        \
		}                                                               \
		return err;                                                     \
	}                                                                   \
	void impl_##name(LLU::MArgumentManager& mngr)

#define LLU_WSTP_FUNCTION(name)                                \
	void impl_##name(WSLINK&); /* forward declaration */       \
	LIBRARY_WSTP_FUNCTION(name) {                              \
		auto err = LLU::ErrorCode::NoError;                    \
		try {                                                  \
			impl_##name(wsl);                                  \
		} catch (const LLU::LibraryLinkError& e) {             \
			err = e.which();                                   \
		} catch (...) {                                        \
			err = LLU::ErrorCode::FunctionError;               \
		}                                                      \
		return err;                                            \
	}                                                          \
	void impl_##name(WSLINK& wsl)
	
#endif // LLU_LIBRARYLINKFUNCTIONMACRO_H
