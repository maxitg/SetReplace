#include <memory>

#include <LLU/Containers/Tensor.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/MArgumentManager.h>

namespace {
	std::unique_ptr<LLU::Tensor<double>> tensor {};
}

EXTERN_C DLLEXPORT mint WolframLibrary_getVersion() {
	return WolframLibraryVersion;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	return 0;
}

LLU_LIBRARY_FUNCTION(loadRealArray) {
	auto genericTensor = mngr.getGenericTensor<LLU::Passing::Shared>(0);
	tensor = std::make_unique<LLU::Tensor<double>>(std::move(genericTensor));
}

LLU_LIBRARY_FUNCTION(getRealArray) {
	if (!tensor) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}
	auto& out = *tensor;
	mngr.set(out);
}

LLU_LIBRARY_FUNCTION(doubleRealArray) {
	if (!tensor) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}
	auto& out = *tensor;
	for (auto& elem : out) {
		elem *= 2;
	}
	mngr.set(out);
}

LLU_LIBRARY_FUNCTION(unloadRealArray) {
	if (!tensor) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}
	mngr.setInteger(tensor->shareCount());
	tensor.reset();
}

// Modify the contents of tensor in C function
LLU_LIBRARY_FUNCTION(add1) {
	auto tx = mngr.getTensor<double, LLU::Passing::Shared>(0);
	for (auto& elem : tx) {
		elem++;
	}
}

LLU_LIBRARY_FUNCTION(copyShared) {
	auto sharedTensor = mngr.getTensor<double, LLU::Passing::Shared>(0);
	auto sc = sharedTensor.shareCount();
	LLU::Tensor<double> copy {sharedTensor.clone()};	   // create deep copy of the shared Tensor. The new Tensor is not Shared
	mngr.setInteger(100 * sc + 10 * sharedTensor.shareCount() + copy.shareCount());
}
