/**
 * @file	NumericArray.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief   Definitions of MContainer<MArgumentType::NumericArray> (GenericNumericArray) methods
 */

#include "LLU/Containers/Generic/NumericArray.hpp"

namespace LLU {
	MContainer<MArgumentType::NumericArray>::MContainer(numericarray_data_t type, mint rank, const mint* dims) {
		Container tmp {};
		if (0 != LibraryData::NumericArrayAPI()->MNumericArray_new(type, rank, dims, &tmp)) {
			ErrorManager::throwException(ErrorName::NumericArrayNewError);
		}
		this->reset(tmp);
	}

	GenericNumericArray GenericNumericArray::convert(numericarray_data_t t, NA::ConversionMethod method, double param) const {
		Container newNA = nullptr;
		auto err = LibraryData::NumericArrayAPI()->MNumericArray_convertType(&newNA, this->getContainer(), t,
																			 static_cast<numericarray_convert_method_t>(method), param);
		if (err != 0) {
			ErrorManager::throwException(ErrorName::NumericArrayConversionError, "Conversion to type " + std::to_string(static_cast<int>(t)) + " failed.");
		}
		return {newNA, Ownership::Library};
	}

	auto GenericNumericArray::cloneImpl() const -> Container {
		Container tmp {};
		if (0 != LibraryData::NumericArrayAPI()->MNumericArray_clone(this->getContainer(), &tmp)) {
			ErrorManager::throwException(ErrorName::NumericArrayCloneError);
		}
		return tmp;
	}

}	 // namespace LLU