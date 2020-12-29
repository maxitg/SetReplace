/**
 * @file	FileUtilities.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief
 */
#ifndef LLU_FILEUTILITIES_H
#define LLU_FILEUTILITIES_H

#include <codecvt>
#include <cstdio>
#include <fstream>
#include <ios>
#include <locale>
#include <memory>
#include <string>

namespace LLU {
	/// Smart pointer type around std::FILE
	using FilePtr = std::unique_ptr<std::FILE, int (*)(std::FILE*)>;

	/**
	 * Create a unique owning pointer of a FILE.
	 * @param   f - a stream pointer obtained from fopen
	 * @return  a smart pointer owning \p f that will call \c fclose on \p f in destructor
	 * @warning if \p f is not a result of \c fopen, the behavior is undefined
	 */
	FilePtr claimFile(std::FILE* f);

	/**
	 * Check if the file \p fileName under open mode \p mode is accessible in the current sandbox setting
	 * @param fileName - file whose path is to be validated
	 * @param mode - file open mode
	 */
	void validatePath(const std::string& fileName, std::ios::openmode mode);

	/**
	 * Convert string from UTF8 to UTF16.
	 * @tparam	T - character type for the result, supported types are char16_t, char32_t, or wchar_t
	 * @param	source - string in UTF8 encoding
	 * @return  copy of the input string converted to UTF16
	 * @note    char16_t and char32_t strings on Windows will be converted to a temporary std::wstring first due to a bug in VS2017
	 */
	template<typename T>
	std::basic_string<T> fromUTF8toUTF16(const std::string& source) {
#ifdef _WIN32
		// On Windows with VS2017 only conversion to wchar_t is supported, so we have no choice here
		std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t> convertor;
		if constexpr (!std::is_same_v<T, wchar_t>) {
			std::wstring tmp = convertor.from_bytes(source);
			return std::basic_string<T> { std::begin(tmp), std::end(tmp) };
		} else {
			return convertor.from_bytes(source);
		}
#else
		std::wstring_convert<std::codecvt_utf8_utf16<T>, T> convertor;
		return convertor.from_bytes(source);
#endif
	}

	/**
	 * Convert string from UTF16 to UTF8.
	 * @tparam  T - character type of the UTF16 string, supported types are char16_t, char32_t, or wchar_t
	 * @param   source - string in UTF16 encoding
	 * @return  copy of the input string converted to UTF8
	 * @note    char16_t and char32_t strings on Windows will be converted to std::wstring before encoding conversion due to a bug in VS2017
	 */
	template<typename T>
	std::string fromUTF16toUTF8(const std::basic_string<T>& source) {
#ifdef _WIN32
		// On Windows with VS2017 only conversion from wchar_t is supported, so we have no choice here
		std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>, wchar_t> convertor;
		if constexpr (!std::is_same_v<T, wchar_t>) {
			return convertor.to_bytes(std::wstring { std::begin(source), std::end(source) });
		} else {
			return convertor.to_bytes(source);
		}
#else
		std::wstring_convert<std::codecvt_utf8_utf16<T>, T> convertor;
		return convertor.to_bytes(source);
#endif
	}

	/**
	 * Convert string from UTF8 to UTF32.
	 * @tparam  T - character type for the result
	 * @param   source - string in UTF8 encoding
	 * @return  copy of the input string converted to UTF32
	 */
	template<typename T>
	std::basic_string<T> fromUTF8toUTF32(const std::string& source) {
#ifdef _WIN32
		// On Windows with VS2017 we always convert to uint32_t
		std::wstring_convert<std::codecvt_utf8<uint32_t>, uint32_t> convertor;
		if constexpr (!std::is_same_v<T, uint32_t>) {
			std::basic_string<uint32_t> tmp = convertor.from_bytes(source);
			return std::basic_string<T> { std::begin(tmp), std::end(tmp) };
		} else {
			return convertor.from_bytes(source);
		}
#else
		std::wstring_convert<std::codecvt_utf8<T>, T> convertor;
		return convertor.from_bytes(source);
#endif
	}

	/**
	 * Convert string from UTF32 to UTF8.
	 * @tparam  T - character type of the UTF32 string
	 * @param   source - string in UTF32 encoding
	 * @return  copy of the input string converted to UTF8
	 */
	template<typename T>
	std::string fromUTF32toUTF8(const std::basic_string<T>& source) {
#ifdef _WIN32
		// On Windows with VS2017 we always convert from uint32_t
		std::wstring_convert<std::codecvt_utf8<uint32_t>, uint32_t> convertor;
		if constexpr (!std::is_same_v<T, uint32_t>) {
			return convertor.to_bytes(std::basic_string<uint32_t> { std::begin(source), std::end(source) });
		} else {
			return convertor.to_bytes(source);
		}
#else
		std::wstring_convert<std::codecvt_utf8<T>, T> convertor;
		return convertor.to_bytes(source.data());
#endif
	}

	/**
	 * @brief   Base class for shared access policies on Windows.
	 * @details Library users are encouraged to provide their own derived classes if needed.
	 * Implemented also on Mac and Linux to have uniform interface but does not make much sense on those platforms.
	 */
	struct SharePolicy {
		virtual ~SharePolicy() = default;

		/**
		 * Base share policy - shared read access when file opened readonly, exclusive access otherwise.
		 * @return _SH_SECURED on Windows and 0 on other platforms where it is not used anyway
		 */
		virtual int flag(std::ios::openmode /*mode*/) const;
	};

	/**
	 * @brief   Default policy for Import/Export paclets - always allow reading, deny writing when we write.
	 * @note    This policy allows for reading from the file when other applications are writing to it which may have unexpected consequences.
	 */
	struct AlwaysReadExclusiveWrite : SharePolicy {
		int flag(std::ios::openmode m) const override;
	};

	/**
	 * Open given file with specified mode (read, write, append, etc.).
	 * Checks with WolframLibraryData if the path is "valid" (we don't know what that really means).
	 * Converts file name to UTF-16 wide string on Windows. Uses open modes from std::ios.
	 * @param   fileName - path to the input file
	 * @param   mode - file open mode
	 * @param   shp - shared access policy, only used on Windows. See https://docs.microsoft.com/en-us/cpp/c-runtime-library/sharing-constants
	 * @return  Unique pointer to opened file
	 * @throw   ErrorName::OpenFileFailed if the file could not be opened
	 */
	FilePtr openFile(const std::string& fileName, std::ios::openmode mode, const SharePolicy& shp = AlwaysReadExclusiveWrite {});

	/**
	 * Open a file stream with specified mode (read, write, append, etc.).
	 * Checks with WolframLibraryData if the path is "valid" (we don't know what that really means).
	 * Converts file name to UTF-16 wide string on Windows.
	 * @param   fileName - path to the input file
	 * @param   mode - file open mode
	 * @param   shp - shared access policy, only used on Windows. See https://docs.microsoft.com/en-us/cpp/c-runtime-library/sharing-constants
	 * @return  Valid file stream
	 * @throw   ErrorName::OpenFileFailed if the file could not be opened
	 */
	std::fstream openFileStream(const std::string& fileName, std::ios::openmode mode, const SharePolicy& shp = AlwaysReadExclusiveWrite {});
} // namespace LLU

#endif	  // LLU_FILEUTILITIES_H
