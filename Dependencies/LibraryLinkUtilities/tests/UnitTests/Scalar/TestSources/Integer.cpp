/**
 * @file	Integer.cpp
 * @brief
 */

#include <LLU/MArgumentManager.h>

static mint value = 0;

EXTERN_C DLLEXPORT int llGet(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);
	mngr.setInteger(value);
	return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int llSet(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);
	value = mngr.getInteger<mint>(0);
	return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int IntegerAdd(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	auto in1 = mngr.getInteger<mint>(0);
	auto in2 = mngr.getInteger<mint>(1);
	auto out = in1 + in2;
	mngr.setInteger(out);
	return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int IntegerTimes(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	auto in1 = mngr.getInteger<mint>(0);
	auto in2 = mngr.getInteger<mint>(1);
	auto out = in1 * in2;
	mngr.set(out);
	return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT int SquareInteger(WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	auto x = mngr.getInteger<mint>(0);
	auto result = x * x;
	mngr.set(result);
	return LIBRARY_NO_ERROR;
}