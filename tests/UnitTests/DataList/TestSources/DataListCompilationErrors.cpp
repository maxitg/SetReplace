/**
 * @file	DataListCompilationErrors.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	07.09.18
 * @brief	Source code for DataList unit tests containing functions that should fail at compile stage.
 */

#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/MArgument.h>

LLU_LIBRARY_FUNCTION(WrongNodeType) {
	auto dsIn = mngr.getDataList<LLU::GenericTensor>(0);
	dsIn.push_back(LLU::Tensor<mint> {2, 3, 4, 5, 6});	  // OK
	dsIn.push_back(3.14);								  // compile time error - "Trying to add DataList node of incorrect type."
	mngr.setDataList(dsIn);
}

LIBRARY_LINK_FUNCTION(TryToAddMArgument) {
	using namespace LLU;
	MArgumentManager mngr {Argc, Args, Res};
	auto dsIn = mngr.getDataList<double>(0);

	PrimitiveWrapper<MArgumentType::MArgument>::addDataStoreNode(dsIn.getContainer(), "", Args[0]); // compile time error - use of deleted function

	mngr.setDataList(dsIn);
	return ErrorCode::NoError;
}

LLU_LIBRARY_FUNCTION(AddMTensorByType) {
	auto dsIn = mngr.getGenericDataList(0);
	dsIn.push_back(LLU::Tensor<mint> {2, 3, 4, 5, 6});	   // OK

	auto* rawMTensor = LLU::Tensor<mint> {2, 3, 4, 5, 6}.abandonContainer();
	dsIn.push_back<LLU::MArgumentType::Tensor>(rawMTensor);  // OK
	dsIn.push_back(rawMTensor);  // static assert failure

	auto* rawMNumericArray = LLU::NumericArray<mint> {2, 3, 4, 5, 6}.abandonContainer();
	dsIn.push_back(rawMNumericArray);  // static assert failure
	mngr.set(dsIn);
}