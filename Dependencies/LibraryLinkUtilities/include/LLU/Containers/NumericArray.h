/**
 * @file	NumericArray.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	6/07/2017
 *
 * @brief	Templated C++ wrapper for MNumericArray
 *
 */
#ifndef LLU_CONTAINERS_NUMERICARRAY_H_
#define LLU_CONTAINERS_NUMERICARRAY_H_

#include <initializer_list>
#include <type_traits>

#include "LLU/Containers/Generic/NumericArray.hpp"
#include "LLU/Containers/MArray.hpp"
#include "LLU/LibraryData.h"
#include "LLU/Utilities.hpp"

namespace LLU {

	/**
	 *  @brief  Typed interface for NumericArray.
	 *
	 *  Provides iterators, data access and info about dimensions.
	 *  @tparam T - type of data in NumericArray
	 */
	template<typename T>
	class TypedNumericArray : public MArray<T> {
	public:
		using MArray<T>::MArray;
	private:
		/**
		 *   @brief Return raw pointer to underlying data
		 *   @return  raw pointer to values of type \p T - contents of the NumericArray
		 **/
		T* getData() const noexcept override {
			return static_cast<T*>(LibraryData::NumericArrayAPI()->MNumericArray_getData(this->getInternal()));
		}

		virtual MNumericArray getInternal() const = 0;
	};

	/**
	 * @class NumericArray
	 * @brief This is a class template, where template parameter T is the type of data elements. NumericArray is derived from MArray.
	 *
	 * NumericArray<> classes automate creation and deletion of MNumericArrays.
	 * They are strongly typed (no void* to underlying memory) and almost all functions from \<algorithms\> can be used on NumericArray.
	 *
	 * @tparam	T - type of underlying data
	 */
	template<typename T>
	class NumericArray : public TypedNumericArray<T>, public GenericNumericArray {
	public:
		/**
		 *   @brief         Constructs flat NumericArray based on a list of elements
		 *   @param[in]     v - initializer list with NumericArray elements
		 *   @throws		see NumericArray<T>::NumericArray(InputIt, InputIt, std::initializer_list<mint>)
		 *
		 *   @warning		It is user's responsibility to make sure that length of v fits into mint!
		 **/
		NumericArray(std::initializer_list<T> v);

		/**
		 * @brief   Constructs flat NumericArray with contents copied from a given collection of data
		 * @tparam  Container - any iterable (begin(), end()) collection of data that has a \c value_type alias member and a size() member function
		 * @param   c - const reference to a collection from which data will be copied to the NumericArray
		 */
		template<class Container, typename = std::enable_if_t<is_iterable_container_with_matching_type_v<Container, T> && has_size_v<Container>>>
		explicit NumericArray(const Container& c) : NumericArray(c, {static_cast<mint>(c.size())}) {}

		/**
		 * @brief   Constructs a NumericArray with contents copied from a given collection of data and dimensions passed as parameter
		 * @tparam  Container  - any iterable (begin(), end()) collection of data that has a \c value_type alias member
		 * @param   c - const reference to a collection from which data will be copied to the NumericArray
		 * @param   dims - dimensions of the NumericArray
		 */
		template<class Container, typename = std::enable_if_t<is_iterable_container_with_matching_type_v<Container, T>>>
		NumericArray(const Container& c, MArrayDimensions dims) : NumericArray(std::begin(c), std::end(c), std::move(dims)) {}

		/**
		 *   @brief         Constructs flat NumericArray with elements from range [first, last)
		 *   @param[in]     first - iterator to the beginning of range
		 *   @param[in]		last - iterator past the end of range
		 *   @tparam		InputIt - any iterator conforming to InputIterator concept
		 *   @throws		see NumericArray<T>::NumericArray(InputIt, InputIt, std::initializer_list<mint>)
		 *
		 *   @warning		It is user's responsibility to make sure that length of range fits into mint!
		 *   @note			Be aware that efficiency of this constructor strongly depends on whether the InputIt is also a RandomAccessIterator
		 **/
		template<class InputIt, typename = enable_if_input_iterator<InputIt>>
		NumericArray(InputIt first, InputIt last);

		/**
		 *   @brief         Constructs the NumericArray of given shape with all elements initialized to given value
		 *   @param[in]     init - value of type \b T to initialize all elements of the NumericArray
		 *   @param[in]     dims - container with NumericArray dimensions
		 **/
		NumericArray(T init, MArrayDimensions dims);

		/**
		 *   @brief         Constructs the NumericArray of given shape with elements from range [first, last)
		 *   @param[in]     first - iterator to the beginning of range
		 *   @param[in]		last - iterator past the end of range
		 *   @param[in]     dims - container with NumericArray dimensions
		 *   @tparam		Container - any type of container that has member \b value_type and this type is convertible to mint
		 *   @throws		ErrorName::NumericArrayNewError - if number of elements in \c v does not match total NumericArray size indicated by \c dims
		 *   @throws		see NumericArray<T>::createInternal() and MArray<T>::MArray(Container&&)
		 **/
		template<class InputIt, typename = enable_if_input_iterator<InputIt>>
		NumericArray(InputIt first, InputIt last, MArrayDimensions dims);

		/**
		 *   @brief     Constructs NumericArray based on MNumericArray
		 *   @param[in] na - LibraryLink structure to be wrapped
		 *   @param[in] owner - who manages the memory the raw MNumericArray
		 *   @throws    ErrorName::NumericArrayTypeError - if the NumericArray template type \b T does not match the actual data type of the MNumericArray
		 **/
		NumericArray(MNumericArray na, Ownership owner);

		/**
		 *   @brief     Create new NumericArray from a GenericNumericArray
		 *   @param[in] na - generic NumericArray to be wrapped into NumericArray class
		 *   @throws	ErrorName::NumericArrayTypeError - if the NumericArray template type \b T does not match the actual data type of the generic
		 *              NumericArray
		 **/
		explicit NumericArray(GenericNumericArray na);

		/**
		 *   @brief         Create NumericArray from generic NumericArray
		 *   @param[in]     other - const reference to a generic NumericArray
		 *   @param[in]		method - conversion method to be used, when in doubt use NA::ConversionMethod::ClipRound as default
		 *   @param[in]     param - conversion tolerance
		 **/
		explicit NumericArray(const GenericNumericArray& other, NA::ConversionMethod method, double param = 0.0);

		/**
		 * Default constructor, creates a "hollow" NumericArray that does not have underlying MNumericArray
		 */
		NumericArray() = default;

		/**
		 * @brief   Clone this NumericArray, performing a deep copy of the underlying MNumericArray.
		 * @note    The cloned MNumericArray always belongs to the library (Ownership::Library) because LibraryLink has no idea of its existence.
		 * @return  new NumericArray
		 */
		NumericArray clone() const {
			return NumericArray {cloneContainer(), Ownership::Library};
		}

	private:
		using GenericBase = GenericNumericArray;

		MNumericArray getInternal() const noexcept override {
			return this->getContainer();
		}
	};

	template<typename T>
	NumericArray<T>::NumericArray(std::initializer_list<T> v) : NumericArray(std::begin(v), std::end(v), {static_cast<mint>(v.size())}) {}

	template<typename T>
	template<class InputIt, typename>
	NumericArray<T>::NumericArray(InputIt first, InputIt last) : NumericArray(first, last, {static_cast<mint>(std::distance(first, last))}) {}

	template<typename T>
	NumericArray<T>::NumericArray(T init, MArrayDimensions dims)
		: TypedNumericArray<T>(std::move(dims)), GenericBase(NumericArrayType<T>, this->rank(), this->dimensions().data()) {
		std::fill(this->begin(), this->end(), init);
	}

	template<typename T>
	template<class InputIt, typename>
	NumericArray<T>::NumericArray(InputIt first, InputIt last, MArrayDimensions dims)
		: TypedNumericArray<T>(std::move(dims)), GenericBase(NumericArrayType<T>, this->rank(), this->dimensions().data()) {
		if (std::distance(first, last) != this->getFlattenedLength()) {
			ErrorManager::throwException(ErrorName::NumericArrayNewError, "Length of data range does not match specified dimensions");
		}
		std::copy(first, last, this->begin());
	}

	template<typename T>
	NumericArray<T>::NumericArray(GenericBase na) : TypedNumericArray<T>({na.getDimensions(), na.getRank()}), GenericBase(std::move(na)) {
		if (NumericArrayType<T> != GenericBase::type()) {
			ErrorManager::throwException(ErrorName::NumericArrayTypeError);
		}
	}

	template<typename T>
	NumericArray<T>::NumericArray(MNumericArray na, Ownership owner) : NumericArray(GenericBase {na, owner}) {}

	template<typename T>
	NumericArray<T>::NumericArray(const GenericNumericArray& other, NA::ConversionMethod method, double param)
		: TypedNumericArray<T>({other.getDimensions(), other.getRank()}), GenericBase(other.convert(NumericArrayType<T>, method, param)) {}

} /* namespace LLU */

#endif /* LLU_CONTAINERS_NUMERICARRAY_H_ */
