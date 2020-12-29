/**
 * @file
 * Definition of the LibraryData class.
 * This file is the only place in LLU where LibraryLink header files are included. It is done this way to solve the include order dependency issue which was
 * present in LibraryLink before WL version 12.1.
 */
#ifndef LLU_LIBRARYDATA_H
#define LLU_LIBRARYDATA_H

#include <memory>

/* If wstp.h has not been included before WolframLibrary.h, we need to detect if we are dealing with WL 12.0- or 12.1+.
 * To achieve this we include a small header file dllexport.h which defines DLLIMPORT macro only since 12.1. */

#pragma push_macro("DLLIMPORT") /* Although unlikely, DLLIMPORT might have been defined elsewhere, so save it and temporarily undefine. */
#undef DLLIMPORT

#include "dllexport.h"

#ifndef DLLIMPORT	/* We are dealing with WL 12.0-, restore DLLIMPORT macro and include wstp.h even though we don't really need it at this point. */
#pragma pop_macro("DLLIMPORT")

#include "wstp.h"

#define MLINK WSLINK
#define MLENV WSENV

#include "WolframLibrary.h"

#else // 12.1+

#include "WolframLibrary.h"

#endif	/* DLLIMPORT */


#include "WolframIOLibraryFunctions.h"
#include "WolframImageLibrary.h"
#include "WolframNumericArrayLibrary.h"
#include "WolframSparseLibrary.h"

namespace LLU {

	/**
	 * @struct 	LibraryData
	 * @brief	This structure offers a static copy of WolframLibData accessible throughout the whole life of the DLL.
	 */
	struct LibraryData {
		/**
		 *   @brief     Set WolframLibraryData structure as static member of LibDataHolder. Call this function in WolframLibrary_initialize.
		 *   @param[in] ld - WolframLibraryData passed to every library function via LibraryLink
		 *   @warning	This function must be called before constructing the first MArgumentManager
		 *   unless you use a constructor that takes WolframLibraryData as argument
		 **/
		static void setLibraryData(WolframLibraryData ld);

		/**
		 * @brief   Check if libData is populated
		 * @return  true iff the libData is not a nullptr
		 */
		static bool hasLibraryData();

		/**
		 *   @brief     Get currently owned WolframLibraryData, if any.
		 *   @return    a non-owning pointer to current instance of st_WolframLibraryData statically stored by LibraryData
		 *   @throws    ErrorName::LibDataError - if libData is nullptr
		 **/
		static WolframLibraryData API();

		/**
		 * @brief   Get a pointer to structure with function pointers to MNumericArray API
		 * @return  a pointer to raw LibraryLink MNumericArray API
		 */
		static const st_WolframNumericArrayLibrary_Functions* NumericArrayAPI();

		/**
		 * @brief   Get a pointer to structure with function pointers to MSparseArray API
		 * @return  a pointer to raw LibraryLink MSparseArray API
		 */
		static const st_WolframSparseLibrary_Functions* SparseArrayAPI();

		/**
		 * @brief   Get a pointer to structure with function pointers to MImage API
		 * @return  a pointer to raw LibraryLink MImage API
		 */
		static const st_WolframImageLibrary_Functions* ImageAPI();

		/**
		 * @brief   Get a pointer to structure with function pointers to DataStore API
		 * @return  a pointer to raw LibraryLink DataStore API
		 */
		static const st_WolframIOLibrary_Functions* DataStoreAPI();

		/**
		 * @brief   Get currently owned WolframLibraryData, even if it is a nullptr.
		 * @return  raw pointer to st_WolframLibraryData statically stored by LibraryData
		 */
		static WolframLibraryData uncheckedAPI() noexcept;

	private:
		/// A copy of WolframLibraryData that will be accessible to all parts of LLU
		static WolframLibraryData libData;
	};

} // namespace LLU

#endif // LLU_LIBRARYDATA_H
