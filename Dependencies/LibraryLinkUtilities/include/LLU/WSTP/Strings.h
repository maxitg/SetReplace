/**
 * @file	Strings.h
 * @date	Mar 22, 2018
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Definitions of multiple structures and type aliases related to string handling in WSTP
 */
#ifndef LLU_WSTP_STRINGS_H_
#define LLU_WSTP_STRINGS_H_

#include <algorithm>
#include <functional>
#include <memory>

#include "wstp.h"

#include "LLU/ErrorLog/Errors.h"
#include "LLU/Utilities.hpp"
#include "LLU/WSTP/EncodingTraits.hpp"
#include "LLU/WSTP/Utilities.h"

namespace LLU::WS {

	/**
	 * @brief Contains configuration parameters that paclet developers may modify
	 */
	namespace EncodingConfig {
		/// Global configuration parameter defining a substitute character required in WSGetByteString.
		/// The default value is \b 26
		extern long substituteCodeForByteEncoding;

		/// Global configuration parameter specifying whether to use a faster version of sending UTF8 strings.
		/// It means that if a string only have ASCII characters then much faster WSPutByteString is used. The time of checking if the string
		/// only has ASCII characters is negligible compared to the time taken by WSPut*String, so this parameter is by default set to \b true.
		extern bool useFastUTF8;
	} // namespace EncodingConfig

	template<Encoding E>
	struct ReleaseString;

	/// StringData with Encoding \p E is a unique_ptr to an array of E-encoded characters
	/// It allows you to take ownership of raw string data from WSTP without making extra copies.
	template<Encoding E>
	using StringData = std::unique_ptr<const CharType<E>[], ReleaseString<E>>;

	/// GetStringFuncT is a type of WSTP function that reads string from a link, e.g. WSGetByteString
	template<typename T>
	using GetStringFuncT = std::function<int(WSLINK, const T**, int*, int*)>;

	/// PutStringFuncT is a type of WSTP function that sends string data to a link, e.g. WSPutByteString
	template<typename T>
	using PutStringFuncT = std::function<int(WSLINK, const T*, int)>;

	/// ReleaseStringFuncT is a type of WSTP function to release string data allocated by WSTP, e.g. WSReleaseByteString
	template<typename T>
	using ReleaseStringFuncT = std::function<void(WSLINK, const T*, int)>;

	template<Encoding E>
	struct String {

		using CharT = CharType<E>;

		static GetStringFuncT<CharT> Get;
		static PutStringFuncT<CharT> Put;
		static ReleaseStringFuncT<CharT> Release;

		static const std::string GetFName;
		static const std::string PutFName;

		template<typename T>
		static void put(WSLINK m, const T* string, int len) {
			static_assert(CharacterTypesCompatible<E, T>, "Character type does not match the encoding in WS::String<E>::put");
			// NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): sorry :(
			auto* expectedStr = reinterpret_cast<const CharT*>(string);
			Detail::checkError(m, Put(m, expectedStr, len), ErrorName::WSPutStringError, PutFName);
		}

		static StringData<E> get(WSLINK m) {
			const CharT* rawResult {};
			int bytes {};
			int characters {};
			Detail::checkError(m, Get(m, &rawResult, &bytes, &characters), ErrorName::WSGetStringError, GetFName);
			return {rawResult, ReleaseString<E> {m, bytes, characters}};
		}

		template<typename T>
		static std::basic_string<T> getString(WSLINK m) {
			static_assert(CharacterTypesCompatible<E, T>, "Character type does not match the encoding in WS::String<E>::getString");
			using StringType = std::basic_string<T>;

			auto strData {get(m)};

			auto bytes = strData.get_deleter().getLength();
			// NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): sorry :(
			auto* expectedData = reinterpret_cast<const T*>(strData.get());
			auto strlen = static_cast<typename StringType::size_type>(bytes);

			return (bytes < 0 ? StringType {expectedData} : StringType {expectedData, strlen});
		}
	};

	/**
	 * @cond
	 * Explicit specialization of String class for undefined encoding.
	 * Its sole purpose is to trigger nice compilation errors.
	 */
	template<>
	struct String<Encoding::Undefined> {

		template<typename T>
		static void put(WSLINK /*link*/, const T* /*stringData*/, int /*length*/) {
			static_assert(dependent_false_v<T>, "Trying to use WS::String<Encoding::Undefined>::put");
		}

		template<typename T = char>
		static T* get(WSLINK /*link*/) {
			static_assert(dependent_false_v<T>, "Trying to use WS::String<Encoding::Undefined>::get");
			return nullptr;
		}

		template<typename T>
		static std::basic_string<T> getString(WSLINK /*link*/) {
			static_assert(dependent_false_v<T>, "Trying to use WS::String<Encoding::Undefined>::getString");
			return {};
		}
	};
	/// @endcond

	template<Encoding E>
	struct ReleaseString {
		ReleaseString() = default;
		ReleaseString(WSLINK m, int l, int c) : m(m), length(l), chars(c) {}

		void operator()(const CharType<E>* data) {
			String<E>::Release(m, data, length);
		}

		int getLength() const {
			return length;
		}

		int getCharacters() const {
			return chars;
		}

	private:
		WSLINK m = nullptr;
		int length = 0;
		int chars = 0;
	};

/// @cond
#ifndef _WIN32

/// Macro for declaring specializations of static members for WS::String<Encoding::E>
/// For internal use only.
#define WS_STRING_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(E)              \
	template<>                                                              \
	GetStringFuncT<CharType<Encoding::E>> String<Encoding::E>::Get;         \
	template<>                                                              \
	PutStringFuncT<CharType<Encoding::E>> String<Encoding::E>::Put;         \
	template<>                                                              \
	ReleaseStringFuncT<CharType<Encoding::E>> String<Encoding::E>::Release; \
	template<>                                                              \
	const std::string String<Encoding::E>::GetFName;                        \
	template<>                                                              \
	const std::string String<Encoding::E>::PutFName;

	WS_STRING_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(Native)
	WS_STRING_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(Byte)
	WS_STRING_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(UTF8)
	WS_STRING_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(UTF16)
	WS_STRING_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(UCS2)
	WS_STRING_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(UTF32)

#else

	template<>
	GetStringFuncT<CharType<Encoding::Native>> String<Encoding::Native>::Get = [](WSLINK m, const char** strData, int* len, int* charCnt) {
		*len = *charCnt = -1;
		return WSGetString(m, strData);
	};
	template<>
	PutStringFuncT<CharType<Encoding::Native>> String<Encoding::Native>::Put = [](WSLINK m, const char* strData, int) { return WSPutString(m, strData); };
	template<>
	ReleaseStringFuncT<CharType<Encoding::Native>> String<Encoding::Native>::Release = [](WSLINK m, const char* strData, int) { WSReleaseString(m, strData); };
	template<>
	const std::string String<Encoding::Native>::GetFName = "WSGetString";
	template<>
	const std::string String<Encoding::Native>::PutFName = "WSPutString";

	template<>
	GetStringFuncT<CharType<Encoding::Byte>> String<Encoding::Byte>::Get = [](WSLINK m, const unsigned char** strData, int* len, int* charCnt) {
		*charCnt = -1;
		return WSGetByteString(m, strData, len, EncodingConfig::substituteCodeForByteEncoding);
	};
	template<>
	PutStringFuncT<CharType<Encoding::Byte>> String<Encoding::Byte>::Put = WSPutByteString;
	template<>
	ReleaseStringFuncT<CharType<Encoding::Byte>> String<Encoding::Byte>::Release = WSReleaseByteString;
	template<>
	const std::string String<Encoding::Byte>::GetFName = "WSGetByteString";
	template<>
	const std::string String<Encoding::Byte>::PutFName = "WSPutByteString";

	namespace {
		// Nested lambdas are too much for MSVC, so we define this helper function separately
		bool allASCIIQ(const unsigned char* strData, int len) {
			return std::all_of(strData, strData + len, [](unsigned char c) -> bool { return c <= 127; });
		}
	}

	template<>
	GetStringFuncT<CharType<Encoding::UTF8>> String<Encoding::UTF8>::Get = WSGetUTF8String;
	template<>
	PutStringFuncT<CharType<Encoding::UTF8>> String<Encoding::UTF8>::Put = [](WSLINK m, const unsigned char* strData, int len) -> int {
		if (EncodingConfig::useFastUTF8 && allASCIIQ(strData, len)) {
			return WSPutByteString(m, strData, len);
		} else {
			return WSPutUTF8String(m, strData, len);
		}
	};
	template<>
	ReleaseStringFuncT<CharType<Encoding::UTF8>> String<Encoding::UTF8>::Release = WSReleaseUTF8String;
	template<>
	const std::string String<Encoding::UTF8>::GetFName = "WSGetUTF8String";
	template<>
	const std::string String<Encoding::UTF8>::PutFName = "WSPut(UTF8/Byte)String";

	template<>
	GetStringFuncT<CharType<Encoding::UTF16>> String<Encoding::UTF16>::Get = WSGetUTF16String;
	template<>
	PutStringFuncT<CharType<Encoding::UTF16>> String<Encoding::UTF16>::Put = WSPutUTF16String;
	template<>
	ReleaseStringFuncT<CharType<Encoding::UTF16>> String<Encoding::UTF16>::Release = WSReleaseUTF16String;
	template<>
	const std::string String<Encoding::UTF16>::GetFName = "WSGetUTF16String";
	template<>
	const std::string String<Encoding::UTF16>::PutFName = "WSPutUTF16String";

	template<>
	GetStringFuncT<CharType<Encoding::UCS2>> String<Encoding::UCS2>::Get = [](WSLINK m, const unsigned short** strData, int* len, int* charCnt) {
		*charCnt = -1;
		return WSGetUCS2String(m, strData, len);
	};
	template<>
	PutStringFuncT<CharType<Encoding::UCS2>> String<Encoding::UCS2>::Put = WSPutUCS2String;
	template<>
	ReleaseStringFuncT<CharType<Encoding::UCS2>> String<Encoding::UCS2>::Release = WSReleaseUCS2String;
	template<>
	const std::string String<Encoding::UCS2>::GetFName = "WSGetUCS2String";
	template<>
	const std::string String<Encoding::UCS2>::PutFName = "WSPutUCS2String";

	template<>
	GetStringFuncT<CharType<Encoding::UTF32>> String<Encoding::UTF32>::Get = [](WSLINK m, const unsigned int** strData, int* len, int* charCnt) {
		*charCnt = -1;
		return WSGetUTF32String(m, strData, len);
	};
	template<>
	PutStringFuncT<CharType<Encoding::UTF32>> String<Encoding::UTF32>::Put = WSPutUTF32String;
	template<>
	ReleaseStringFuncT<CharType<Encoding::UTF32>> String<Encoding::UTF32>::Release = WSReleaseUTF32String;
	template<>
	const std::string String<Encoding::UTF32>::GetFName = "WSGetUTF32String";
	template<>
	const std::string String<Encoding::UTF32>::PutFName = "WSPutUTF32String";

#endif
/// @endcond
} /* namespace LLU::WS */

#endif /* LLU_WSTP_STRINGS_H_ */
