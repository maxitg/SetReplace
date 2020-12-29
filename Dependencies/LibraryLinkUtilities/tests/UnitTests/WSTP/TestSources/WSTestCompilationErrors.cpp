/**
 * @file	WSTestCompilationErrors.cpp
 * @date	Jan 30, 2018
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Source code for WSTPStream unit tests.
 */
#include <iostream>

#include "wstp.h"

#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/WSTP/WSStream.hpp>

using LLU::WSStream;
namespace WS = LLU::WS;

// This function should trigger compiler errors
LIBRARY_WSTP_FUNCTION(Wrong) {
	auto err = LLU::ErrorCode::NoError;
	try {
		WSStream<WS::Encoding::UCS2, WS::Encoding::UTF16> ml(wsl, "List", 0);

		ml << "Hello";	  // ERROR (static_assert): "Character type does not match the encoding in WS::String<E>::put"

		ml << WS::putAs<WS::Encoding::Native>("Hello");	   // This should be fine

		std::basic_string<unsigned char> s;

		ml >> s;	// ERROR (static_assert): "Character type does not match the encoding in WS::String<E>::getString"

		ml >> WS::getAs<WS::Encoding::UTF8>(s);	   // This should be fine

		unsigned int i {129};

		ml >> i;	// ERROR (static_assert): "Calling operator>> with unsupported type."

		ml << i;	// ERROR (static_assert): "Calling operator<< with unsupported type."

		i = WS::GetScalar<unsigned int>::get(wsl);	  // ERROR (static_assert): Trying to use WS::GetScalar<T> for unsupported type T

		WS::PutScalar<unsigned int>::put(wsl, i);	 // ERROR (static_assert): Trying to use WS::PutScalar<T> for unsupported type T

		ml << static_cast<wsint64>(i);	  // This should be fine

	} catch (LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLU::ErrorCode::FunctionError;
	}
	return err;
}
