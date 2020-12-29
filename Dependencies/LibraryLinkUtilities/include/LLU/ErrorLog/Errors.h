/**
 * @file	Errors.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	March 31, 2019
 * @brief	Definitions of error names and error codes used across LLU.
 */
#ifndef LLU_ERRORLOG_ERRORS_H
#define LLU_ERRORLOG_ERRORS_H

#include <string>

namespace LLU {

	/**
	 * @brief Error codes predefined in Library Link
	 */
	namespace ErrorCode {

		// Original LibraryLink error codes:
		constexpr int VersionError = 7;		  ///< same as LIBRARY_VERSION_ERROR
		constexpr int FunctionError = 6;	  ///< same as LIBRARY_FUNCTION_ERROR
		constexpr int MemoryError = 5;		  ///< same as LIBRARY_MEMORY_ERROR
		constexpr int NumericalError = 4;	  ///< same as LIBRARY_NUMERICAL_ERROR
		constexpr int DimensionsError = 3;	  ///< same as LIBRARY_DIMENSIONS_ERROR
		constexpr int RankError = 2;		  ///< same as LIBRARY_RANK_ERROR
		constexpr int TypeError = 1;		  ///< same as LIBRARY_TYPE_ERROR
		constexpr int NoError = 0;			  ///< same as LIBRARY_NO_ERROR
	}  // namespace ErrorCode

	/**
	 * @brief Names of all errors used across LLU
	 */
	namespace ErrorName {

		// Original LibraryLink error codes:
		extern const std::string VersionError;		 ///< same as LIBRARY_VERSION_ERROR
		extern const std::string FunctionError;		 ///< same as LIBRARY_FUNCTION_ERROR
		extern const std::string MemoryError;		 ///< same as LIBRARY_MEMORY_ERROR
		extern const std::string NumericalError;	 ///< same as LIBRARY_NUMERICAL_ERROR
		extern const std::string DimensionsError;	 ///< same as LIBRARY_DIMENSIONS_ERROR
		extern const std::string RankError;			 ///< same as LIBRARY_RANK_ERROR
		extern const std::string TypeError;			 ///< same as LIBRARY_TYPE_ERROR
		extern const std::string NoError;			 ///< same as LIBRARY_NO_ERROR

		// LibraryData errors
		extern const std::string LibDataError;	  ///< WolframLibraryData is not set

		// MArgument errors:
		extern const std::string MArgumentIndexError;			///< wrong argument index
		extern const std::string MArgumentNumericArrayError;	///< error involving NumericArray argument
		extern const std::string MArgumentTensorError;			///< error involving Tensor argument
		extern const std::string MArgumentImageError;			///< error involving Image argument

		// ErrorManager errors:
		extern const std::string ErrorManagerThrowIdError;		 ///< trying to throw exception with non-existent id
		extern const std::string ErrorManagerThrowNameError;	 ///< trying to throw exception with non-existent name
		extern const std::string ErrorManagerCreateNameError;	 ///< trying to register exception with already existing name

		// NumericArray errors:
		extern const std::string NumericArrayNewError;			 ///< creating new NumericArray failed
		extern const std::string NumericArrayCloneError;		 ///< NumericArray cloning failed
		extern const std::string NumericArrayTypeError;			 ///< NumericArray type mismatch
		extern const std::string NumericArraySizeError;			 ///< wrong assumption about NumericArray size
		extern const std::string NumericArrayIndexError;		 ///< trying to access non-existing element
		extern const std::string NumericArrayConversionError;	 ///< conversion from NumericArray of different type failed

		// MTensor errors:
		extern const std::string TensorNewError;	  ///< creating new MTensor failed
		extern const std::string TensorCloneError;	  ///< MTensor cloning failed
		extern const std::string TensorTypeError;	  ///< Tensor type mismatch
		extern const std::string TensorSizeError;	  ///< wrong assumption about Tensor size
		extern const std::string TensorIndexError;	  ///< trying to access non-existing element

		// MImage errors:
		extern const std::string ImageNewError;		 ///< creating new MImage failed
		extern const std::string ImageCloneError;	 ///< MImage cloning failed
		extern const std::string ImageTypeError;	 ///< Image type mismatch
		extern const std::string ImageSizeError;	 ///< wrong assumption about Image size
		extern const std::string ImageIndexError;	 ///< trying to access non-existing element

		// General container errors:
		extern const std::string CreateFromNullError;		   ///< attempting to create a generic container from nullptr
		extern const std::string MArrayElementIndexError;	   ///< attempting to access MArray element at invalid index
		extern const std::string MArrayDimensionIndexError;	   ///< attempting to access MArray dimension at invalid index

		// WSTP errors:
		extern const std::string WSNullWSLinkError;			   ///< Trying to create WSStream with NULL WSLINK
		extern const std::string WSTestHeadError;			   ///< WSTestHead failed (wrong head or number of arguments)
		extern const std::string WSPutSymbolError;			   ///< WSPutSymbol failed
		extern const std::string WSPutFunctionError;		   ///< WSPutFunction failed
		extern const std::string WSTestSymbolError;			   ///< WSTestSymbol failed (different symbol on the link than expected)
		extern const std::string WSWrongSymbolForBool;		   ///< Tried to read something else than "True" or "False" as boolean
		extern const std::string WSGetListError;			   ///< Could not get list from WSTP
		extern const std::string WSGetScalarError;			   ///< Could not get scalar from WSTP
		extern const std::string WSGetStringError;			   ///< Could not get string from WSTP
		extern const std::string WSGetArrayError;			   ///< Could not get array from WSTP
		extern const std::string WSPutListError;			   ///< Could not send list via WSTP
		extern const std::string WSPutScalarError;			   ///< Could not send scalar via WSTP
		extern const std::string WSPutStringError;			   ///< Could not send string via WSTP
		extern const std::string WSPutArrayError;			   ///< Could not send array via WSTP
		extern const std::string WSGetSymbolError;			   ///< WSGetSymbol failed
		extern const std::string WSGetFunctionError;		   ///< WSGetFunction failed
		extern const std::string WSPacketHandleError;		   ///< One of the packet handling functions failed
		extern const std::string WSFlowControlError;		   ///< One of the flow control functions failed
		extern const std::string WSTransferToLoopbackError;	   ///< Something went wrong when transferring expressions from loopback link
		extern const std::string WSCreateLoopbackError;		   ///< Could not create a new loopback link
		extern const std::string WSLoopbackStackSizeError;	   ///< Loopback stack size too small to perform desired action

		// DataList errors:
		extern const std::string DLNullRawNode;			 ///< DataStoreNode passed to Node wrapper was null
		extern const std::string DLInvalidNodeType;		 ///< DataStoreNode passed to Node wrapper carries data of invalid type
		extern const std::string DLGetNodeDataError;	 ///< DataStoreNode_getData failed
		extern const std::string DLSharedDataStore;	 	 ///< Trying to create a Shared DataStore. DataStore can only be passed as Automatic or Manual.
		extern const std::string DLPushBackTypeError;	 ///< Element to be added to the DataList has incorrect type

		// MArgument errors:
		extern const std::string ArgumentCreateNull;		  ///< Trying to create PrimitiveWrapper object from nullptr
		extern const std::string ArgumentAddNodeMArgument;	  ///< Trying to add DataStore Node of type MArgument (aka MType_Undef)

		// ProgressMonitor errors:
		extern const std::string Aborted;	 ///< Computation aborted by the user

		// ManagedExpression errors:
		extern const std::string ManagedExprInvalidID;	  ///< Given number is not an ID of any existing managed expression
		extern const std::string MLEDynamicTypeError;	  ///< Invalid dynamic type requested for a Managed Library Expression
		extern const std::string MLENullInstance; 		  ///< Missing managed object for a valid ID

		// FileUtilities errors:
		extern const std::string PathNotValidated;		///< Given file path could not be validated under desired open mode
		extern const std::string InvalidOpenMode;		///< Specified open mode is invalid
		extern const std::string OpenFileFailed;		///< Could not open file
	}  // namespace ErrorName

}  // namespace LLU

#endif	  // LLU_ERRORLOG_ERRORS_H
