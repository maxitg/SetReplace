/**
 * @file
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief   Definition and implementation of NumericArrayView and NumericArrayTypedView.
 */
#ifndef LLU_CONTAINERS_VIEWS_NUMERICARRAY_HPP
#define LLU_CONTAINERS_VIEWS_NUMERICARRAY_HPP

#include "LLU/Containers/Generic/NumericArray.hpp"
#include "LLU/Containers/Interfaces.h"
#include "LLU/Containers/Iterators/IterableContainer.hpp"

namespace LLU {

	/**
	 * @brief   Simple, light-weight, non-owning, data-type-agnostic wrappper over MNumericArray.
	 *
	 * Intended for use in functions that only need to access MNumericArray metadata, where it can alleviate the need for introducing template parameters
	 * for MNumericArray passing mode (like in GenericNumericArray) or data type (like in NumericArray class).
	 */
	class NumericArrayView : public NumericArrayInterface {
	public:
		NumericArrayView() = default;

		/**
		 * Create a NumericArrayView from a GenericNumericArray
		 * @param gNA - a GenericNumericArray
		 */
		NumericArrayView(const GenericNumericArray& gNA) : na {gNA.getContainer()} {}	 // NOLINT: implicit conversion is useful and harmless

		/**
		 * Create a NumericArrayView from a raw MNumericArray
		 * @param mna - a raw MNumericArray
		 */
		NumericArrayView(MNumericArray mna) : na {mna} {}	 // NOLINT:

		/// @copydoc NumericArrayInterface::getRank()
		mint getRank() const override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getRank(na);
		}

		/// @copydoc NumericArrayInterface::getDimensions()
		mint const* getDimensions() const override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getDimensions(na);
		}

		/// @copydoc NumericArrayInterface::getFlattenedLength()
		mint getFlattenedLength() const override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getFlattenedLength(na);
		}

		/// @copydoc NumericArrayInterface::type()
		numericarray_data_t type() const final {
			return LibraryData::NumericArrayAPI()->MNumericArray_getType(na);
		}

		/// @copydoc NumericArrayInterface::rawData()
		void* rawData() const noexcept override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getData(na);
		}

	private:
		MNumericArray na = nullptr;
	};

	/**
	 * @brief   Simple, light-weight, non-owning wrappper over MNumericArray.
	 * Intended for use where a temporary "upgrade" of a raw MNumericArray to a complete, strongly-typed NumericArray interface would be useful.
	 *
	 * @tparam  T - type of the NumericArray data
	 */
	template<typename T>
	class NumericArrayTypedView : public NumericArrayView, public IterableContainer<T> {
	public:
		NumericArrayTypedView() = default;

		/**
		 * Create a NumericArrayTypedView from a GenericNumericArray.
		 * @param gNA - a GenericNumericArray
		 * @throws ErrorName::NumericArrayTypeError - if the actual datatype of \p gNA is not T
		 */
		NumericArrayTypedView(const GenericNumericArray& gNA) : NumericArrayView(gNA) {	   // NOLINT: implicit conversion is useful and harmless
			if (NumericArrayType<T> != type()) {
				ErrorManager::throwException(ErrorName::NumericArrayTypeError);
			}
		}

		/**
		 * Create a NumericArrayTypedView from a NumericArrayView.
		 * @param nav - a NumericArrayView
		 * @throws ErrorName::NumericArrayTypeError - if the actual datatype of \p nav is not T
		 */
		NumericArrayTypedView(NumericArrayView nav) : NumericArrayView(std::move(nav)) {	// NOLINT
			if (NumericArrayType<T> != type()) {
				ErrorManager::throwException(ErrorName::NumericArrayTypeError);
			}
		}

		/**
		 * Create a NumericArrayTypedView from a raw MNumericArray.
		 * @param mna - a raw MNumericArray
		 * @throws ErrorName::NumericArrayTypeError - if the actual datatype of \p mna is not T
		 */
		NumericArrayTypedView(MNumericArray mna) : NumericArrayView(mna) {	  // NOLINT
			if (NumericArrayType<T> != type()) {
				ErrorManager::throwException(ErrorName::NumericArrayTypeError);
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
	 * Take a NumericArray-like object \p na and a function \p callable and call the function with a NumericArrayTypedView created from \p na
	 * @tparam  NumericArrayT - a NumericArray-like type (GenericNumericArray, NumericArrayView or MNumericAray)
	 * @tparam  F - any callable object
	 * @param   na - NumericArray-like object on which an operation will be performed
	 * @param   callable - a callable object that can be called with a NumericArrayTypedView of any type
	 * @return  result of calling \p callable on a NumericArrayTypedView over \p na
	 */
	template<typename NumericArrayT, typename F>
	auto asTypedNumericArray(NumericArrayT&& na, F&& callable) {
		switch (na.type()) {
			case MNumericArray_Type_Bit8: return std::forward<F>(callable)(NumericArrayTypedView<std::int8_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_UBit8: return std::forward<F>(callable)(NumericArrayTypedView<std::uint8_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_Bit16: return std::forward<F>(callable)(NumericArrayTypedView<std::int16_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_UBit16: return std::forward<F>(callable)(NumericArrayTypedView<std::uint16_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_Bit32: return std::forward<F>(callable)(NumericArrayTypedView<std::int32_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_UBit32: return std::forward<F>(callable)(NumericArrayTypedView<std::uint32_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_Bit64: return std::forward<F>(callable)(NumericArrayTypedView<std::int64_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_UBit64: return std::forward<F>(callable)(NumericArrayTypedView<std::uint64_t> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_Real32: return std::forward<F>(callable)(NumericArrayTypedView<float> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_Real64: return std::forward<F>(callable)(NumericArrayTypedView<double> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_Complex_Real32:
				return std::forward<F>(callable)(NumericArrayTypedView<std::complex<float>> {std::forward<NumericArrayT>(na)});
			case MNumericArray_Type_Complex_Real64:
				return std::forward<F>(callable)(NumericArrayTypedView<std::complex<double>> {std::forward<NumericArrayT>(na)});
			default: ErrorManager::throwException(ErrorName::NumericArrayTypeError);
		}
	}

	/// @cond
	// Specialization of asTypedNumericArray for MNumericArray
	template<typename F>
	auto asTypedNumericArray(MNumericArray na, F&& callable) {
		return asTypedNumericArray(NumericArrayView {na}, std::forward<F>(callable));
	}
	/// @endcond
}  // namespace LLU

#endif	  // LLU_CONTAINERS_VIEWS_NUMERICARRAY_HPP
