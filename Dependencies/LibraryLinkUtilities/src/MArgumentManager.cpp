/**
 * @file	MArgumentManager.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	18/04/2017
 *
 * @brief	Definitions of non-template member functions and static data members from MArgumentManager class
 *
 */

#include "LLU/MArgumentManager.h"

#include <algorithm>

#include "LLU/Containers/MArray.hpp"
#include "LLU/LibraryData.h"

namespace LLU {

	/* Static data members */

	std::string MArgumentManager::stringResultBuffer;

	/* Constructors */

	MArgumentManager::MArgumentManager(mint Argc, MArgument* Args, MArgument& Res) : argc(Argc), args(Args), res(Res) {
		initStringArgs();
	}

	MArgumentManager::MArgumentManager(WolframLibraryData ld, mint Argc, MArgument* Args, MArgument& Res) : argc(Argc), args(Args), res(Res) {
		LibraryData::setLibraryData(ld);
		initStringArgs();
	}

	/* Other member functions */

	bool MArgumentManager::getBoolean(size_type index) const {
		return (MArgument_getBoolean(getArgs(index)) != False);
	}

	double MArgumentManager::getReal(size_type index) const {
		return static_cast<double>(MArgument_getReal(getArgs(index)));
	}

	void MArgumentManager::acquireUTF8String(size_type index) const {
		if (!stringArgs.at(index)) {
			char* strArg = MArgument_getUTF8String(getArgs(index));
			stringArgs[index].reset(strArg);
		}
	}

	char* MArgumentManager::getCString(size_type index) const {
		acquireUTF8String(index);
		return stringArgs[index].get();
	}

	std::string MArgumentManager::getString(size_type index) const {
		acquireUTF8String(index);
		return stringArgs[index].get();
	}

	namespace {
		void setStringAsMArgument(MArgument& res, const std::string& str) {
			// NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast): LibraryLink will not modify the string, so const_cast is safe here
			MArgument_setUTF8String(res, const_cast<char*>(str.c_str()));
		}
	}

	void MArgumentManager::setString(const std::string& str) {
		stringResultBuffer = str;
		setStringAsMArgument(res, stringResultBuffer);
	}

	void MArgumentManager::setString(std::string&& str) {
		stringResultBuffer = std::move(str);
		setStringAsMArgument(res, stringResultBuffer);
	}

	void MArgumentManager::setString(const char* str) {
		stringResultBuffer = str;
		setStringAsMArgument(res, stringResultBuffer);
	}

	void MArgumentManager::setBoolean(bool result) noexcept {
		MArgument_setBoolean(res, result ? True : False);
	}

	void MArgumentManager::setReal(double result) noexcept {
		MArgument_setReal(res, result);
	}

	void MArgumentManager::setInteger(mint result) noexcept {
		MArgument_setInteger(res, result);
	}

	std::complex<double> MArgumentManager::getComplex(size_type index) const {
		auto* mc = MArgument_getComplexAddress(getArgs(index));
		return {mc->ri[0], mc->ri[1]};
	}

	void MArgumentManager::setComplex(std::complex<double> c) noexcept {
		mcomplex mc {{c.real(), c.imag()}};
		MArgument_setComplex(res, mc);
	}

	MNumericArray MArgumentManager::getMNumericArray(size_type index) const {
		return MArgument_getMNumericArray(getArgs(index));
	}

	MTensor MArgumentManager::getMTensor(size_type index) const {
		return MArgument_getMTensor(getArgs(index));
	}

	MImage MArgumentManager::getMImage(size_type index) const {
		return MArgument_getMImage(getArgs(index));
	}

	DataStore MArgumentManager::getDataStore(size_type index) const {
		//NOLINTNEXTLINE(cppcoreguidelines-pro-type-cstyle-cast): c-style cast used in a macro in WolframIOLibraryFunctions.h
		return MArgument_getDataStore(getArgs(index));
	}

	void MArgumentManager::setMNumericArray(MNumericArray na) {
		MArgument_setMNumericArray(res, na);
	}

	void MArgumentManager::setMTensor(MTensor t) {
		MArgument_setMTensor(res, t);
	}

	void MArgumentManager::setMImage(MImage im) {
		MArgument_setMImage(res, im);
	}

	void MArgumentManager::setDataStore(DataStore ds) {
		//NOLINTNEXTLINE(cppcoreguidelines-pro-type-cstyle-cast): c-style cast used in a macro in WolframIOLibraryFunctions.h
		MArgument_setDataStore(res, ds);
	}

	void MArgumentManager::setSparseArray(MSparseArray sa) {
		MArgument_setMSparseArray(res, sa);
	}

	numericarray_data_t MArgumentManager::getNumericArrayType(size_type index) const {
		MNumericArray tmp = MArgument_getMNumericArray(getArgs(index));
		return LibraryData::NumericArrayAPI()->MNumericArray_getType(tmp);
	}

	unsigned char MArgumentManager::getTensorType(size_type index) const {
		MTensor tmp = MArgument_getMTensor(getArgs(index));
		return static_cast<unsigned char>(LibraryData::API()->MTensor_getType(tmp));
	}

	imagedata_t MArgumentManager::getImageType(size_type index) const {
		MImage tmp = MArgument_getMImage(getArgs(index));
		return LibraryData::ImageAPI()->MImage_getDataType(tmp);
	}

	MArgument MArgumentManager::getArgs(size_type index) const {
		if (index >= static_cast<size_type >(argc)) {
			ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentIndexError,
			                                          "Index " + std::to_string(index) + " out-of-bound when accessing LibraryLink argument");
		}
		// NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): to be fixed in C++20 with std::span
		return args[index];
	}

	void MArgumentManager::initStringArgs() {
		stringArgs.reserve(argc);
		for (int i = 0; i < argc; ++i) {
			stringArgs.emplace_back(nullptr, LibraryData::API()->UTF8String_disown);
		}
	}

	ProgressMonitor MArgumentManager::getProgressMonitor(double step) const {
		if (argc < 1) {
			ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentIndexError, "Index too small when accessing ProgressMonitor.");
		}
		auto pmIndex = static_cast<size_type>(argc - 1);	   // shared Tensor will be passed as the last argument
		auto sharedIndicator = getTensor<double, Passing::Shared>(pmIndex);
		return ProgressMonitor {std::move(sharedIndicator), step};
	}

} /* namespace LLU */
