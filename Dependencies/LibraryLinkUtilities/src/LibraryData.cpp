/**
 * @file
 * Implementation of the LibraryData class.
 */

#include "LLU/LibraryData.h"

#include "LLU/ErrorLog/ErrorManager.h"

namespace LLU {

	WolframLibraryData LibraryData::libData = nullptr;

	void LibraryData::setLibraryData(WolframLibraryData ld) {
		libData = ld;
	}

	bool LibraryData::hasLibraryData() {
		return libData != nullptr;
	}

	WolframLibraryData LibraryData::API() {
		if (!libData) {
			ErrorManager::throwException(ErrorName::LibDataError);
		}
		return libData;
	}

	WolframLibraryData LibraryData::uncheckedAPI() noexcept {
		return libData;
	}

	const st_WolframNumericArrayLibrary_Functions* LibraryData::NumericArrayAPI() {
		return API()->numericarrayLibraryFunctions;
	}

	const st_WolframSparseLibrary_Functions* LibraryData::SparseArrayAPI() {
		return API()->sparseLibraryFunctions;
	}

	const st_WolframImageLibrary_Functions* LibraryData::ImageAPI() {
		return API()->imageLibraryFunctions;
	}

	const st_WolframIOLibrary_Functions* LibraryData::DataStoreAPI() {
		return API()->ioLibraryFunctions;
	}

}  // namespace LLU
