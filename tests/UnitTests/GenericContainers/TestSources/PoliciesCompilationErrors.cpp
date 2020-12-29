/**
 * @file	PoliciesCompilationErrors.cpp
 * @brief
 */

#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

using LLU::Passing;

LIBRARY_LINK_FUNCTION(DisownManual) {
	LLU::NumericArray<uint8_t> na {1, 2, 3, 4, 5};
	na.disown();
	return 0;
}

LIBRARY_LINK_FUNCTION(CopyAutomatic) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	LLU::GenericTensor t = mngr.getGenericTensor(0);
	auto copy = t;
	return 0;
}

LIBRARY_LINK_FUNCTION(CopyShared) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto t = mngr.getGenericImage<Passing::Shared>(0);
	auto copy = t;
	return 0;
}

LIBRARY_LINK_FUNCTION(SharedDataStore) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto ds = mngr.getGenericDataList<Passing::Shared>(0);
	return 0;
}

LIBRARY_LINK_FUNCTION(MoveShared) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto na = mngr.getGenericNumericArray<Passing::Shared>(0);
	LLU::GenericNumericArray clone { std::move(na), LLU::Ownership::LibraryLink };	  // cannot move Shared to Automatic
	return 0;
}