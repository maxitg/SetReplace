/**
 * @file	Errors.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	March 31, 2019
 */

#include "LLU/ErrorLog/Errors.h"

/// Helper macro for defining new errors so that for each error we have a std::string variable equal to the error name.
#define LLU_DEFINE_ERROR_NAME(errorIdentifier) const std::string errorIdentifier = #errorIdentifier

namespace LLU::ErrorName {
	/// @cond
	LLU_DEFINE_ERROR_NAME(VersionError);
	LLU_DEFINE_ERROR_NAME(FunctionError);
	LLU_DEFINE_ERROR_NAME(MemoryError);
	LLU_DEFINE_ERROR_NAME(NumericalError);
	LLU_DEFINE_ERROR_NAME(DimensionsError);
	LLU_DEFINE_ERROR_NAME(RankError);
	LLU_DEFINE_ERROR_NAME(TypeError);
	LLU_DEFINE_ERROR_NAME(NoError);

	LLU_DEFINE_ERROR_NAME(LibDataError);

	LLU_DEFINE_ERROR_NAME(MArgumentIndexError);
	LLU_DEFINE_ERROR_NAME(MArgumentNumericArrayError);
	LLU_DEFINE_ERROR_NAME(MArgumentTensorError);
	LLU_DEFINE_ERROR_NAME(MArgumentImageError);

	LLU_DEFINE_ERROR_NAME(ErrorManagerThrowIdError);
	LLU_DEFINE_ERROR_NAME(ErrorManagerThrowNameError);
	LLU_DEFINE_ERROR_NAME(ErrorManagerCreateNameError);

	LLU_DEFINE_ERROR_NAME(NumericArrayNewError);
	LLU_DEFINE_ERROR_NAME(NumericArrayCloneError);
	LLU_DEFINE_ERROR_NAME(NumericArrayTypeError);
	LLU_DEFINE_ERROR_NAME(NumericArraySizeError);
	LLU_DEFINE_ERROR_NAME(NumericArrayIndexError);
	LLU_DEFINE_ERROR_NAME(NumericArrayConversionError);

	LLU_DEFINE_ERROR_NAME(TensorNewError);
	LLU_DEFINE_ERROR_NAME(TensorCloneError);
	LLU_DEFINE_ERROR_NAME(TensorTypeError);
	LLU_DEFINE_ERROR_NAME(TensorSizeError);
	LLU_DEFINE_ERROR_NAME(TensorIndexError);

	LLU_DEFINE_ERROR_NAME(ImageNewError);
	LLU_DEFINE_ERROR_NAME(ImageCloneError);
	LLU_DEFINE_ERROR_NAME(ImageTypeError);
	LLU_DEFINE_ERROR_NAME(ImageSizeError);
	LLU_DEFINE_ERROR_NAME(ImageIndexError);

	LLU_DEFINE_ERROR_NAME(CreateFromNullError);
	LLU_DEFINE_ERROR_NAME(MArrayElementIndexError);
	LLU_DEFINE_ERROR_NAME(MArrayDimensionIndexError);

	LLU_DEFINE_ERROR_NAME(WSNullWSLinkError);
	LLU_DEFINE_ERROR_NAME(WSTestHeadError);
	LLU_DEFINE_ERROR_NAME(WSPutSymbolError);
	LLU_DEFINE_ERROR_NAME(WSPutFunctionError);
	LLU_DEFINE_ERROR_NAME(WSTestSymbolError);
	LLU_DEFINE_ERROR_NAME(WSWrongSymbolForBool);
	LLU_DEFINE_ERROR_NAME(WSGetListError);
	LLU_DEFINE_ERROR_NAME(WSGetScalarError);
	LLU_DEFINE_ERROR_NAME(WSGetStringError);
	LLU_DEFINE_ERROR_NAME(WSGetArrayError);
	LLU_DEFINE_ERROR_NAME(WSPutListError);
	LLU_DEFINE_ERROR_NAME(WSPutScalarError);
	LLU_DEFINE_ERROR_NAME(WSPutStringError);
	LLU_DEFINE_ERROR_NAME(WSPutArrayError);
	LLU_DEFINE_ERROR_NAME(WSGetSymbolError);
	LLU_DEFINE_ERROR_NAME(WSGetFunctionError);
	LLU_DEFINE_ERROR_NAME(WSPacketHandleError);
	LLU_DEFINE_ERROR_NAME(WSFlowControlError);
	LLU_DEFINE_ERROR_NAME(WSTransferToLoopbackError);
	LLU_DEFINE_ERROR_NAME(WSCreateLoopbackError);
	LLU_DEFINE_ERROR_NAME(WSLoopbackStackSizeError);

	LLU_DEFINE_ERROR_NAME(DLNullRawNode);
	LLU_DEFINE_ERROR_NAME(DLInvalidNodeType);
	LLU_DEFINE_ERROR_NAME(DLGetNodeDataError);
	LLU_DEFINE_ERROR_NAME(DLSharedDataStore);
	LLU_DEFINE_ERROR_NAME(DLPushBackTypeError);

	LLU_DEFINE_ERROR_NAME(ArgumentCreateNull);
	LLU_DEFINE_ERROR_NAME(ArgumentAddNodeMArgument);

	LLU_DEFINE_ERROR_NAME(Aborted);

	LLU_DEFINE_ERROR_NAME(ManagedExprInvalidID);
	LLU_DEFINE_ERROR_NAME(MLEDynamicTypeError);
	LLU_DEFINE_ERROR_NAME(MLENullInstance);

	LLU_DEFINE_ERROR_NAME(PathNotValidated);
	LLU_DEFINE_ERROR_NAME(InvalidOpenMode);
	LLU_DEFINE_ERROR_NAME(OpenFileFailed);
	/// @endcond
}	 // namespace LLU::ErrorName
