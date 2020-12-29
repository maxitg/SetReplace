/**
 * @file	Real.cpp
 * @brief
 */

#include <LLU/MArgumentManager.h>

EXTERN_C DLLEXPORT int RealAdd(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	auto in1 = mngr.getReal(0);
	auto in2 = mngr.getReal(1);
	auto out = in1 + in2;
	mngr.setReal(out);
	return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int RealTimes(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	auto in1 = mngr.getReal(0);
	auto in2 = mngr.getReal(1);
	auto out = in1 * in2;
	mngr.set(out);
	return LIBRARY_NO_ERROR;
}