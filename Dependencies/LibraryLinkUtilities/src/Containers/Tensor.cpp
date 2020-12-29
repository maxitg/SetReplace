/**
 * @file	Tensor.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	18/04/2017
 *
 * @brief	Template specialization of certain methods from TypedTensor class for all underlying data types that we support
 *
 */

#include "LLU/Containers/Tensor.h"

#include <complex>

namespace LLU {

	MContainer<MArgumentType::Tensor>::MContainer(mint type, mint rank, const mint* dims) {
		Container tmp {};
		if (0 != LibraryData::API()->MTensor_new(type, rank, dims, &tmp)) {
			ErrorManager::throwException(ErrorName::TensorNewError);
		}
		this->reset(tmp);
	}

	void* GenericTensor::rawData() const {
		switch (type()) {
			case MType_Integer: return LibraryData::API()->MTensor_getIntegerData(this->getContainer());
			case MType_Real: return LibraryData::API()->MTensor_getRealData(this->getContainer());
			case MType_Complex: return LibraryData::API()->MTensor_getComplexData(this->getContainer());
			default: ErrorManager::throwException(ErrorName::TensorTypeError);
		}
	}

	auto GenericTensor::cloneImpl() const -> Container {
		Container tmp {};
		if (0 != LibraryData::API()->MTensor_clone(this->getContainer(), &tmp)) {
			ErrorManager::throwException(ErrorName::TensorCloneError);
		}
		return tmp;
	}

	/// @cond
	template<>
	mint* TypedTensor<mint>::getData() const noexcept {
		return LibraryData::API()->MTensor_getIntegerData(this->getInternal());
	}

	template<>
	double* TypedTensor<double>::getData() const noexcept {
		return LibraryData::API()->MTensor_getRealData(this->getInternal());
	}

	template<>
	std::complex<double>* TypedTensor<std::complex<double>>::getData() const noexcept {
		// NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): std::complex<double> is binary compatible with mcomplex
		return reinterpret_cast<std::complex<double>*>(LibraryData::API()->MTensor_getComplexData(this->getInternal()));
	}
	/// @endcond
} /* namespace LLU */
