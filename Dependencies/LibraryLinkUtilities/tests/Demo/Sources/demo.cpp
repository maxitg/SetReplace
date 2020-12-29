/**
 * @file	demo.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief
 */

#include <LLU/LLU.h>

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	try {
		LLU::LibraryData::setLibraryData(libData);
		LLU::ErrorManager::registerPacletErrors({
			{"InvalidCharacterError", "Message \"`m`\" contains non-ASCII character(s)."},
			{"NegativeShiftError", "Requested negative shift `s`."},
		});

	} catch (const LLU::LibraryLinkError& e) {
		return e.which();
	}
	return LLU::ErrorCode::NoError;
}

namespace {
	constexpr std::string_view alphabet {"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"};
}

std::string performCaesarCipher(const std::string& message, mint shift) {
	if (shift < 0) {
		LLU::ErrorManager::throwException("NegativeShiftError", shift);
	}

	auto resultStr {message};
	for (auto& c : resultStr) {
		auto index = alphabet.find(c);
		if (index == std::string::npos) {
			LLU::ErrorManager::throwException("InvalidCharacterError", message);
		}
		c = alphabet[(index + shift) % alphabet.length()];
	}
	return resultStr;
}

EXTERN_C DLLEXPORT int CaesarCipherEncode(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
	try {
		LLU::MArgumentManager mngr {libData, Argc, Args, Res};
		auto str = mngr.getString(0);
		const auto shift = mngr.getInteger<mint>(1);
		auto result = performCaesarCipher(str, shift);
		mngr.set(result);
	} catch (const LLU::LibraryLinkError& e) {
		return e.which();
	}
	return LLU::ErrorCode::NoError;
}

EXTERN_C DLLEXPORT int CaesarCipherDecode(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
	try {
		LLU::MArgumentManager mngr {libData, Argc, Args, Res};
		auto str = mngr.getString(0);
		const auto shift = mngr.getInteger<mint>(1);
		auto result = performCaesarCipher(str, alphabet.length() - shift);
		mngr.set(result);
	} catch (const LLU::LibraryLinkError& e) {
		return e.which();
	}
	return LLU::ErrorCode::NoError;
}