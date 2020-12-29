/**
 * @file
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief   Definition and implementation of TensorView and TensorTypedView.
 */
#ifndef LLU_CONTAINERS_VIEWS_TENSOR_HPP
#define LLU_CONTAINERS_VIEWS_TENSOR_HPP

#include "LLU/Containers/Generic/Tensor.hpp"
#include "LLU/Containers/Interfaces.h"
#include "LLU/Containers/Iterators/IterableContainer.hpp"

namespace LLU {

	/**
	 * @brief   Simple, light-weight, non-owning wrappper over MTensor.
	 *
	 * Intended for use in functions that only need to access MTensor metadata, where it can alleviate the need for introducing template parameters
	 * for MTensor passing mode (like in GenericTensor) or data type (like in Tensor class).
	 */
	class TensorView : public TensorInterface {
	public:
		TensorView() = default;

		/**
		 * Create a NumericArrayView from a GenericNumericArray
		 * @param gTen - a GenericNumericArray
		 */
		TensorView(const GenericTensor& gTen) : t {gTen.getContainer()} {}	  // NOLINT: implicit conversion to a view is useful and harmless

		/**
		 * Create a NumericArrayView from a raw MNumericArray
		 * @param mt - a raw MNumericArray
		 */
		TensorView(MTensor mt) : t {mt} {}	  // NOLINT

		/// @copydoc TensorInterface::getRank()
		mint getRank() const override {
			return LibraryData::API()->MTensor_getRank(t);
		}

		/// @copydoc TensorInterface::getDimensions()
		mint const* getDimensions() const override {
			return LibraryData::API()->MTensor_getDimensions(t);
		}

		/// @copydoc TensorInterface::getFlattenedLength()
		mint getFlattenedLength() const override {
			return LibraryData::API()->MTensor_getFlattenedLength(t);
		}

		/// @copydoc TensorInterface::type()
		mint type() const final {
			return LibraryData::API()->MTensor_getType(t);
		}

		/// @copydoc TensorInterface::rawData()
		void* rawData() const override {
			switch (type()) {
				case MType_Integer: return LibraryData::API()->MTensor_getIntegerData(t);
				case MType_Real: return LibraryData::API()->MTensor_getRealData(t);
				case MType_Complex: return LibraryData::API()->MTensor_getComplexData(t);
				default: return nullptr;
			}
		}

	private:
		MTensor t = nullptr;
	};

	template<typename T>
	class TensorTypedView : public TensorView, public IterableContainer<T> {
	public:
		TensorTypedView() = default;

		/**
		 * Create a TensorTypedView from a GenericTensor.
		 * @param gTen - a GenericTensor
		 * @throws ErrorName::TensorTypeError - if the actual datatype of \p gTen is not T
		 */
		TensorTypedView(const GenericTensor& gTen) : TensorView(gTen) {	   // NOLINT: implicit conversion to a view is useful and harmless
			if (TensorType<T> != type()) {
				ErrorManager::throwException(ErrorName::TensorTypeError);
			}
		}

		/**
		 * Create a TensorTypedView from a TensorView.
		 * @param tv - a TensorView
		 * @throws ErrorName::TensorTypeError - if the actual datatype of \p tv is not T
		 */
		TensorTypedView(TensorView tv) : TensorView(std::move(tv)) {	// NOLINT
			if (TensorType<T> != type()) {
				ErrorManager::throwException(ErrorName::TensorTypeError);
			}
		}

		/**
		 * Create a TensorTypedView from a raw MTensor.
		 * @param mt - a raw MTensor
		 * @throws ErrorName::TensorTypeError - if the actual datatype of \p mt is not T
		 */
		TensorTypedView(MTensor mt) : TensorView(mt) {	  // NOLINT
			if (TensorType<T> != type()) {
				ErrorManager::throwException(ErrorName::TensorTypeError);
			}
		}

	private:
		T* getData() const noexcept override {
			return static_cast<T*>(rawData());
		}

		mint getSize() const noexcept override {
			return getFlattenedLength();
		}
	};

	/**
	 * Take a Tensor-like object \p t and a function \p callable and call the function with a TensorTypedView created from \p t
	 * @tparam  TensorT - a Tensor-like type (GenericTensor, TensorView or MNumericAray)
	 * @tparam  F - any callable object
	 * @param   t - Tensor-like object on which an operation will be performed
	 * @param   callable - a callable object that can be called with a TensorTypedView of any type
	 * @return  result of calling \p callable on a TensorTypedView over \p t
	 */
	template<typename TensorT, typename F>
	auto asTypedTensor(TensorT&& t, F&& callable) {
		switch (t.type()) {
			case MType_Integer: return std::forward<F>(callable)(TensorTypedView<mint> {std::forward<TensorT>(t)});
			case MType_Real: return std::forward<F>(callable)(TensorTypedView<double> {std::forward<TensorT>(t)});
			case MType_Complex: return std::forward<F>(callable)(TensorTypedView<std::complex<double>> {std::forward<TensorT>(t)});
			default: ErrorManager::throwException(ErrorName::TensorTypeError);
		}
	}

	/// @cond
	// Specialization of asTypedTensor for MTensor
	template<typename F>
	auto asTypedTensor(MTensor t, F&& callable) {
		return asTypedTensor(TensorView {t}, std::forward<F>(callable));
	}
	/// @endcond
}  // namespace LLU

#endif	  // LLU_CONTAINERS_VIEWS_TENSOR_HPP
