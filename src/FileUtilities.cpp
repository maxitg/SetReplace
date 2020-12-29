/**
 * @file	FileUtilities.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief
 */

#include "LLU/NoMinMaxWindows.h"
#include "LLU/FileUtilities.h"

#ifdef _WIN32
#include <share.h>
#endif

#include "LLU/ErrorLog/ErrorManager.h"
#include "LLU/LibraryData.h"
#include "LLU/Utilities.hpp"

namespace LLU {

	namespace {
		std::string openModeString(std::ios::openmode mode) {
			using std::ios;
			bool isBinary = (mode & ios::binary) != 0;
			mode &= ~ios::binary;
			std::string result;
			if (mode == ios::in) {
				result = "r";
			} else if (mode == ios::out || mode == (ios::out | ios::trunc)) {
				result = "w";
			} else if (mode == ios::app || mode == (ios::out | ios::app)) {
				result = "a";
			} else if (mode == (ios::out | ios::in)) {
				result = "r+";
			} else if (mode == (ios::out | ios::in | ios::trunc)) {
				result = "w+";
			} else if (mode == (ios::out | ios::in | ios::app) || mode == (ios::in | ios::app)) {
				result = "a+";
			} else {
				ErrorManager::throwException(ErrorName::InvalidOpenMode);
			}
			return isBinary ? result + "b" : result;
		}

		template<typename CharT>
		std::basic_fstream<CharT> openFileStream(const std::string& fileName, std::ios::openmode mode, const SharePolicy& shp) {
			validatePath(fileName, mode);
			std::basic_fstream<CharT> result;
#ifdef _WIN32
			std::wstring fileNameUTF16 = fromUTF8toUTF16<wchar_t>(fileName);
			result = std::basic_fstream<CharT> {fileNameUTF16.c_str(), mode, shp.flag(mode)};
#else
			Unused(shp);
			result = std::basic_fstream<CharT> {fileName, mode};
#endif /* _WIN32 */
			if (!result) {
				ErrorManager::throwException(ErrorName::OpenFileFailed, fileName);
			}
			return result;
		}
	}  // namespace

	FilePtr claimFile(std::FILE* f) {
		return FilePtr(f, [](std::FILE* fp) { return fp ? std::fclose(fp) : 0; });
	}

	void validatePath(const std::string& fileName, std::ios::openmode mode) {
		char pathMode = (mode & std::ios::out) != 0 || (mode & std::ios::app) != 0 ? 'W' : 'R';
		// NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast): LibraryLink will not modify the string, so const_cast is safe here
		if (LibraryData::API()->validatePath(const_cast<char*>(fileName.c_str()), pathMode) == False) {
			ErrorManager::throwException(ErrorName::PathNotValidated, fileName);
		}
	}

	int SharePolicy::flag(std::ios::openmode /*mode*/) const {
#ifdef _WIN32
		return _SH_SECURE;
#else
		return 0;
#endif
	}

	int AlwaysReadExclusiveWrite::flag(std::ios::openmode m) const {
#ifdef _WIN32
		return (m & std::ios::out || m & std::ios::app) ? _SH_DENYWR : _SH_DENYNO;
#else
		Unused(m);
		return 0;
#endif
	}

	FilePtr openFile(const std::string& fileName, std::ios::openmode mode, const SharePolicy& shp) {
		validatePath(fileName, mode);

		FILE* file = nullptr;
		std::string modeStr = openModeString(mode);
#ifdef _WIN32
		std::wstring fileNameUTF16 = fromUTF8toUTF16<wchar_t>(fileName);
		std::wstring modeWstr = fromUTF8toUTF16<wchar_t>(modeStr);
		int shareFlag = shp.flag(mode);
		file = _wfsopen(fileNameUTF16.c_str(), modeWstr.c_str(), shareFlag);
#else
		Unused(shp);
		file = std::fopen(fileName.c_str(), modeStr.c_str());
#endif /* _WIN32 */
		if (!file) {
			ErrorManager::throwException(ErrorName::OpenFileFailed, fileName);
		}
		return claimFile(file);
	}

	std::fstream openFileStream(const std::string& fileName, std::ios::openmode mode, const SharePolicy& shp) {
		return openFileStream<char>(fileName, mode, shp);
	}

}  // namespace LLU