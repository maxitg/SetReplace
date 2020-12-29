/**
 * @file	Boolean.cpp
 * @brief
 */

#include <LLU/MArgumentManager.h>

EXTERN_C DLLEXPORT int BooleanAnd(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);
	auto in1 = mngr.getBoolean(0);
	auto in2 = mngr.getBoolean(1);
	mngr.setBoolean(in1 && in2);
	return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int BooleanNot(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);
	auto in1 = mngr.getBoolean(0);
	mngr.set(!in1);
	return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int BooleanOr(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);
	auto in1 = mngr.getBoolean(0);
	auto in2 = mngr.getBoolean(1);
	mngr.set(in1 || in2);
	return LIBRARY_NO_ERROR;
}
