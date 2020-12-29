/**
 * @file	WSStringEncodings.cpp
 * @date	Mar 30, 2018
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Test suite for string related functionality of LLU::WSStream
 */

#include <iostream>

#include "wstp.h"

#include <LLU/ErrorLog/ErrorManager.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/WSTP/WSStream.hpp>

using LLU::WS::Encoding;
namespace ErrorCode = LLU::ErrorCode;

template<class Operation, typename... Args>
void forAllEncodingsDo(Args&&... params) {
	Operation::template run<Encoding::Native>(std::forward<Args>(params)...);
	Operation::template run<Encoding::Byte>(std::forward<Args>(params)...);
	Operation::template run<Encoding::UTF8>(std::forward<Args>(params)...);
	Operation::template run<Encoding::UTF16>(std::forward<Args>(params)...);
	Operation::template run<Encoding::UCS2>(std::forward<Args>(params)...);
	Operation::template run<Encoding::UTF32>(std::forward<Args>(params)...);
}

LIBRARY_WSTP_FUNCTION(NestedPutAs) {
	auto err = ErrorCode::NoError;
	try {
		LLU::WSStream<Encoding::Byte, Encoding::UTF32> ml(wsl, 1);

		std::string s;
		ml >> LLU::WS::getAs<Encoding::UTF8>(s);

		ml << LLU::WS::putAs<Encoding::UTF16>(LLU::WS::putAs<Encoding::UTF8>(s));	   // the most nested encoding should be the one used
	} catch (LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = ErrorCode::FunctionError;
	}
	return err;
}

template<typename T>
std::vector<wsint64> toIntegerCodes(const T* p, std::size_t n) {
	std::vector<wsint64> ret {p, std::next(p, n)};
	return ret;
}

struct StringToCharCodes {
	template<Encoding E, typename WSTPStream>
	static void run(WSTPStream ml, WSMARK mark) {
		std::basic_string<LLU::WS::CharType<E>> s;
		if (WSSeekToMark(ml.get(), mark, 0)) {
			ml >> LLU::WS::getAs<E>(s);
			ml << LLU::WS::Rule << LLU::WS::getEncodingName(E) << toIntegerCodes(s.c_str(), s.length());
		}
	}
};

LIBRARY_WSTP_FUNCTION(CharacterCodes) {
	auto err = ErrorCode::NoError;
	try {
		LLU::WSStream<Encoding::Byte> ml(wsl, 1);
		auto* mark = WSCreateMark(wsl);
		ml << LLU::WS::Association(6);	 // there are 6 encodings available
		forAllEncodingsDo<StringToCharCodes>(ml, mark);

	} catch (LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = ErrorCode::FunctionError;
	}
	return err;
}

struct EncodingRoundtrip {
	template<Encoding E, typename WSTPStream>
	static void run(WSTPStream ml, WSMARK mark) {
		std::basic_string<LLU::WS::CharType<E>> s;
		if (WSSeekToMark(ml.get(), mark, 0)) {
			ml >> LLU::WS::getAs<E>(s);
			ml << LLU::WS::Rule << LLU::WS::getEncodingName(E) << LLU::WS::putAs<E>(s);
		}
	}
};

LIBRARY_WSTP_FUNCTION(AllEncodingsRoundtrip) {
	auto err = ErrorCode::NoError;
	try {
		LLU::WSStream<Encoding::Byte> ml(wsl, 1);
		auto* mark = WSCreateMark(wsl);
		ml << LLU::WS::Association(6);	 // there are 6 encodings available
		forAllEncodingsDo<EncodingRoundtrip>(ml, mark);
	} catch (LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = ErrorCode::FunctionError;
	}
	return err;
}
