/**
 * @file	ErrorManager.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	March 21, 2019
 * @brief
 */
#include "LLU/ErrorLog/ErrorManager.h"

#include "LLU/LibraryData.h"
#include "LLU/WSTP/Utilities.h"
#include "LLU/WSTP/WSStream.hpp"

namespace LLU {

	auto ErrorManager::errors() -> ErrorManager::ErrorMap& {
		static ErrorMap errMap = registerLLUErrors({
			// Original LibraryLink error codes:
			{ErrorName::VersionError, "An error was caused by an incompatible function call. The library was compiled with a previous LibraryData version."},
			{ErrorName::FunctionError, "An error occurred in the library function."},
			{ErrorName::MemoryError, "An error was caused by failed memory allocation or insufficient memory."},
			{ErrorName::NumericalError, "A numerical error was encountered."},
			{ErrorName::DimensionsError, "An error caused by inconsistent dimensions or by exceeding array bounds."},
			{ErrorName::RankError, "An error was caused by a tensor with an inconsistent rank."},
			{ErrorName::TypeError, "An error caused by inconsistent types was encountered."},
			{ErrorName::NoError, "No errors occurred."},

			// LibraryData errors:
			{ErrorName::LibDataError, "WolframLibraryData is not set. Make sure to call LibraryData::setLibraryData in WolframLibrary_initialize."},

			// MArgument errors:
			{ErrorName::MArgumentIndexError, "An error was caused by an incorrect argument index."},
			{ErrorName::MArgumentNumericArrayError, "An error was caused by a NumericArray argument."},
			{ErrorName::MArgumentTensorError, "An error was caused by a Tensor argument."},
			{ErrorName::MArgumentImageError, "An error was caused by an Image argument."},

			// ErrorManager errors:
			{ErrorName::ErrorManagerThrowIdError, "An exception was thrown with a non-existent id."},
			{ErrorName::ErrorManagerThrowNameError, "An exception was thrown with a non-existent name."},
			{ErrorName::ErrorManagerCreateNameError, "An exception was registered with a name that already exists."},

			// NumericArray errors:
			{ErrorName::NumericArrayNewError, "Failed to create a new NumericArray."},
			{ErrorName::NumericArrayCloneError, "Failed to clone NumericArray."},
			{ErrorName::NumericArrayTypeError, "An error was caused by an NumericArray type mismatch."},
			{ErrorName::NumericArraySizeError, "An error was caused by an incorrect NumericArray size."},
			{ErrorName::NumericArrayIndexError, "An error was caused by attempting to access a nonexistent NumericArray element."},
			{ErrorName::NumericArrayConversionError, "Failed to convert NumericArray from different type."},

			// MTensor errors:
			{ErrorName::TensorNewError, "Failed to create a new MTensor."},
			{ErrorName::TensorCloneError, "Failed to clone MTensor."},
			{ErrorName::TensorTypeError, "An error was caused by an MTensor type mismatch."},
			{ErrorName::TensorSizeError, "An error was caused by an incorrect Tensor size."},
			{ErrorName::TensorIndexError, "An error was caused by attempting to access a nonexistent Tensor element."},

			// MImage errors:
			{ErrorName::ImageNewError, "Failed to create a new MImage."},
			{ErrorName::ImageCloneError, "Failed to clone MImage."},
			{ErrorName::ImageTypeError, "An error was caused by an MImage type mismatch."},
			{ErrorName::ImageSizeError, "An error was caused by an incorrect Image size."},
			{ErrorName::ImageIndexError, "An error was caused by attempting to access a nonexistent Image element."},

			// General container errors:
			{ErrorName::CreateFromNullError, "Attempting to create a generic container from nullptr."},
			{ErrorName::MArrayElementIndexError, "Attempting to access MArray element at invalid index."},
			{ErrorName::MArrayElementIndexError, "Attempting to access MArray dimension `d` which does not exist."},

			// WSTP errors:
			{ErrorName::WSNullWSLinkError, "Trying to create WSStream with NULL WSLINK"},
			{ErrorName::WSTestHeadError, "WSTestHead failed (wrong head or number of arguments)."},
			{ErrorName::WSPutSymbolError, "WSPutSymbol failed."},
			{ErrorName::WSPutFunctionError, "WSPutFunction failed."},
			{ErrorName::WSTestSymbolError, "WSTestSymbol failed (different symbol on the link than expected)."},
			{ErrorName::WSWrongSymbolForBool, R"(Tried to read something else than "True" or "False" as boolean.)"},
			{ErrorName::WSGetListError, "Could not get list from WSTP."},
			{ErrorName::WSGetScalarError, "Could not get scalar from WSTP."},
			{ErrorName::WSGetStringError, "Could not get string from WSTP."},
			{ErrorName::WSGetArrayError, "Could not get array from WSTP."},
			{ErrorName::WSPutListError, "Could not send list via WSTP."},
			{ErrorName::WSPutScalarError, "Could not send scalar via WSTP."},
			{ErrorName::WSPutStringError, "Could not send string via WSTP."},
			{ErrorName::WSPutArrayError, "Could not send array via WSTP."},
			{ErrorName::WSGetSymbolError, "WSGetSymbol failed."},
			{ErrorName::WSGetFunctionError, "WSGetFunction failed."},
			{ErrorName::WSPacketHandleError, "One of the packet handling functions failed."},
			{ErrorName::WSFlowControlError, "One of the flow control functions failed."},
			{ErrorName::WSTransferToLoopbackError, "Something went wrong when transferring expressions from loopback link."},
			{ErrorName::WSCreateLoopbackError, "Could not create a new loopback link."},
			{ErrorName::WSLoopbackStackSizeError, "Loopback stack size too small to perform desired action."},

			// DataList errors:
			{ErrorName::DLNullRawNode, "DataStoreNode passed to Node wrapper was null"},
			{ErrorName::DLInvalidNodeType, "DataStoreNode passed to Node wrapper carries data of invalid type"},
			{ErrorName::DLGetNodeDataError, "DataStoreNode_getData failed"},
			{ErrorName::DLSharedDataStore, "Trying to create a Shared DataStore. DataStore can only be passed as Automatic or Manual."},
			{ErrorName::DLPushBackTypeError, "Element to be added to the DataList has incorrect type"},

			// MArgument errors:
			{ErrorName::ArgumentCreateNull, "Trying to create PrimitiveWrapper object from nullptr"},
			{ErrorName::ArgumentAddNodeMArgument, "Trying to add DataStore Node of type MArgument (aka MType_Undef)"},

			// ProgressMonitor errors:
			{ErrorName::Aborted, "Computation aborted by the user."},

			// ManagedExpression errors:
			{ErrorName::ManagedExprInvalidID, "Given number is not an ID of any existing managed expression."},
			{ErrorName::MLEDynamicTypeError, "Invalid dynamic type requested for a Managed Library Expression."},
			{ErrorName::MLENullInstance, "Missing managed object for a valid ID."},

			// FileUtilities errors:
			{ErrorName::PathNotValidated, "File path `path` could not be validated under desired open mode."},
			{ErrorName::InvalidOpenMode, "Specified open mode is invalid."},
			{ErrorName::OpenFileFailed,	"Could not open file `f`."},
		});
		return errMap;
	}

	bool ErrorManager::sendParametersImmediately = true;

	int& ErrorManager::nextErrorId() {
		static int id = ErrorCode::VersionError;
		return id;
	}

	auto ErrorManager::registerLLUErrors(std::initializer_list<ErrorStringData> initList) -> ErrorMap {
		ErrorMap e;
		for (auto&& err : initList) {
			e.emplace(err.first, LibraryLinkError {nextErrorId()--, err.first, err.second});
		}
		return e;
	}

	void ErrorManager::registerPacletErrors(const std::vector<ErrorStringData>& errors) {
		for (auto&& err : errors) {
			set(err);
		}
	}

	void ErrorManager::set(const ErrorStringData& errorData) {
		auto& errorMap = errors();
		if (auto [elem, success] = errorMap.emplace(errorData.first, LibraryLinkError {nextErrorId()--, errorData.first, errorData.second}); !success) {
			// Revert nextErrorId because nothing was inserted
			nextErrorId()++;

			// Throw only if someone attempted to insert an error with existing key but different message
			if (elem->second.message() != errorData.second) {
				throw errors().find("ErrorManagerCreateNameError")->second;
			}
		}
	}

	const LibraryLinkError& ErrorManager::findError(int errorId) {
		for (auto&& err : errors()) {
			if (err.second.id() == errorId) {
				return err.second;
			}
		}
		throw errors().find("ErrorManagerThrowIdError")->second;
	}

	const LibraryLinkError& ErrorManager::findError(const std::string& errorName) {
		const auto& exception = errors().find(errorName);
		if (exception == errors().end()) {
			throw errors().find("ErrorManagerThrowNameError")->second;
		}
		return exception->second;
	}

	void ErrorManager::sendRegisteredErrorsViaWSTP(WSLINK mlp) {
		WSStream<WS::Encoding::UTF8> ms(mlp, "List", 0);

		ms << WS::NewPacket << WS::Association(static_cast<int>(errors().size()));

		for (const auto& err : errors()) {
			ms << WS::Rule << err.first << WS::List(2) << err.second.id() << err.second.message();
		}

		ms << WS::EndPacket << WS::Flush;
	}

	/**
	 * LibraryLink function that LLU will call to send all errors registered in C++ to the Wolfram Language layer.
	 * This way LLU is able to translate exceptions from C++ to appropriate Failure expressions in the Wolfram Language.
	 * @param libData - WolframLibraryData
	 * @param mlp - WSTP link to transfer data
	 * @return error code
	 */
	EXTERN_C DLLEXPORT int sendRegisteredErrors([[maybe_unused]] WolframLibraryData libData, WSLINK mlp) {
		auto err = ErrorCode::NoError;
		try {
			ErrorManager::sendRegisteredErrorsViaWSTP(mlp);
		} catch (LibraryLinkError& e) {
			err = e.which();
		} catch (...) {
			err = ErrorCode::FunctionError;
		}
		return err;
	}
}  // namespace LLU
