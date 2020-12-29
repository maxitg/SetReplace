/**
 * @file	MArgumentManagerCompilationErrors.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Source code for MArgumentManager unit tests containing functions that should fail at compile stage.
 */
#include <tuple>

#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

class A {};

LLU_LIBRARY_FUNCTION(UnregisteredArg) {
	[[maybe_unused]] auto f = mngr.get<float>(0); // Compile time error - float does not correspond to any argument type known to MArgumentManager
	[[maybe_unused]] auto a = mngr.get<A>(1); 	// Compile time error - A does not correspond to any argument type known to MArgumentManager
}

LLU_LIBRARY_FUNCTION(UnregisteredRetType) {
	A a;
	mngr.set(a);	// Compile time error - A does not correspond to any return type known to MArgumentManager
}

LLU_LIBRARY_FUNCTION(GetArgsWithIndices) {
	// Compile time error - number of argument types does not match the number of indices in the call to mngr.get<..>(...)
	// gcc also triggers separate error for: "no matching function for call to ‘LLU::MArgumentManager::get<short unsigned int, mint>(<brace-enclosed initializer list>)’"
	[[maybe_unused]] auto [x, y] = mngr.get<unsigned short, mint>({1, 2, 3});
}