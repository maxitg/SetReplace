/**
 * @file	Tensor.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	6/07/2017
 *
 * @brief	Templated C++ wrapper for MTensor
 *
 */
#ifndef LLU_CONTAINERS_TENSOR_H_
#define LLU_CONTAINERS_TENSOR_H_

#include <initializer_list>
#include <type_traits>

#include "LLU/Containers/Generic/Tensor.hpp"
#include "LLU/Containers/MArray.hpp"
#include "LLU/LibraryData.h"
#include "LLU/Utilities.hpp"

namespace LLU {

	/**
	 *  @brief  Typed interface for Tensor.
	 *
	 *  Provides iterators, data access and info about dimensions.
	 *  @tparam T - type of data in Tensor
	 */
	template<typename T>
	class TypedTensor : public MArray<T> {
	public:
		using MArray<T>::MArray;
	private:
		/**
		 * @brief   Get a raw pointer to underlying data
		 * @return  raw pointer to values of type \p T - contents of the Tensor
		 */
		T* getData() const noexcept override;

		/// Get the raw MTensor, must be implemented in subclasses.
		virtual MTensor getInternal() const = 0;
	};

	/**
	 * @class Tensor
	 * @brief This is a class template, where template parameter T is the type of data elements. Tensor is derived from MArray.
	 *
	 * Tensor<> classes automate creation and deletion of MTensors.
	 * They are strongly typed (no void* to underlying memory) and almost all functions from \<algorithms\> can be used on Tensor.
	 *
	 * @tparam	T - type of underlying data
	 */
	template<typename T>
	class Tensor : public TypedTensor<T>, public GenericTensor {
	public:
		/**
		 *   @brief         Constructs flat Tensor based on a list of elements
		 *   @param[in]     v - initializer list with Tensor elements
		 *   @throws		see Tensor<T>::Tensor(InputIt, InputIt, std::initializer_list<mint>)
		 *
		 *   @warning		It is user's responsibility to make sure that length of v fits into mint!
		 **/
		Tensor(std::initializer_list<T> v);

		/**
		 * @brief   Constructs flat Tensor with contents copied from a given collection of data
		 * @tparam  Container - any iterable (begin(), end()) collection of data that has a \c value_type alias member and a size() member function
		 * @param   c - const reference to a collection from which data will be copied to the Tensor
		 */
		template<class Container, typename = std::enable_if_t<is_iterable_container_with_matching_type_v<Container, T> && has_size_v<Container>>>
		explicit Tensor(const Container& c) : Tensor(c, {static_cast<mint>(c.size())}) {}

		/**
		 * @brief   Constructs a Tensor with contents copied from a given collection of data and dimensions passed as parameter
		 * @tparam  Container  - any iterable (begin(), end()) collection of data that has a \c value_type alias member
		 * @param   c - const reference to a collection from which data will be copied to the Tensor
		 * @param   dims - dimensions of the Tensor
		 */
		template<class Container, typename = std::enable_if_t<is_iterable_container_with_matching_type_v<Container, T>>>
		Tensor(const Container& c, MArrayDimensions dims) : Tensor(std::begin(c), std::end(c), std::move(dims)) {}

		/**
		 *   @brief         Constructs flat Tensor with elements from range [first, last)
		 *   @param[in]     first - iterator to the beginning of range
		 *   @param[in]		last - iterator past the end of range
		 *   @tparam		InputIt - any iterator conforming to InputIterator concept
		 *   @throws		see Tensor<T>::Tensor(InputIt, InputIt, std::initializer_list<mint>)
		 *
		 *   @warning		It is user's responsibility to make sure that length of range fits into mint!
		 *   @note			Be aware that efficiency of this constructor strongly depends on whether the InputIt is also a RandomAccessIterator
		 **/
		template<class InputIt, typename = enable_if_input_iterator<InputIt>>
		Tensor(InputIt first, InputIt last);

		/**
		 *   @brief         Constructs the Tensor of given shape with all elements initialized to given value
		 *   @param[in]     init - value of type \b T to initialize all elements of the Tensor
		 *   @param[in]     dims - MArrayDimensions object with Tensor dimensions
		 **/
		Tensor(T init, MArrayDimensions dims);

		/**
		 *   @brief         Constructs the Tensor of given shape with elements from range [first, last)
		 *   @param[in]     first - iterator to the beginning of range
		 *   @param[in]		last - iterator past the end of range
		 *   @param[in]     dims - container with Tensor dimensions
		 *   @tparam		InputIt - any iterator conforming to InputIterator concept
		 *   @throws		ErrorName::TensorNewError - if number of elements in \c v does not match total Tensor size indicated by \c dims
		 **/
		template<class InputIt, typename = enable_if_input_iterator<InputIt>>
		Tensor(InputIt first, InputIt last, MArrayDimensions dims);

		/**
		 *   @brief     Constructs Tensor based on MTensor
		 *   @param[in] t - LibraryLink structure to be wrapped
		 *   @param[in] owner - who manages the memory the raw MTensor
		 *   @throws    ErrorName::TensorTypeError - if the Tensor template type \b T does not match the actual data type of the MTensor
		 **/
		Tensor(MTensor t, Ownership owner);

		/**
		 *   @brief     Create new Tensor from a GenericTensor
		 *   @param[in] t - generic Tensor to be wrapped into Tensor class
		 *   @throws	ErrorName::TensorTypeError - if the Tensor template type \b T does not match the actual data type of the generic Tensor
		 **/
		explicit Tensor(GenericTensor t);

		/**
		 *  @brief  Default constructor, creates a Tensor that does not wrap over any raw MTensor
		 */
		Tensor() = default;

		/**
		 * @brief   Clone this Tensor, performing a deep copy of the underlying MTensor.
		 * @note    The cloned MTensor always belongs to the library (Ownership::Library) because LibraryLink has no idea of its existence.
		 * @return  new Tensor
		 */
		Tensor clone() const {
			return Tensor {cloneContainer(), Ownership::Library};
		}
	private:
		using GenericBase = MContainer<MArgumentType::Tensor>;

		/// @copydoc MContainerBase::getContainer()
		MTensor getInternal() const noexcept override {
			return this->getContainer();
		}
	};

	template<typename T>
	Tensor<T>::Tensor(std::initializer_list<T> v) : Tensor(std::begin(v), std::end(v), {static_cast<mint>(v.size())}) {}

	template<typename T>
	template<class InputIt, typename>
	Tensor<T>::Tensor(InputIt first, InputIt last) : Tensor(first, last, {static_cast<mint>(std::distance(first, last))}) {}

	template<typename T>
	Tensor<T>::Tensor(T init, MArrayDimensions dims)
		: TypedTensor<T>(std::move(dims)), GenericBase(TensorType<T>, this->rank(), this->dimensions().data()) {
		std::fill(this->begin(), this->end(), init);
	}

	template<typename T>
	template<class InputIt, typename>
	Tensor<T>::Tensor(InputIt first, InputIt last, MArrayDimensions dims)
		: TypedTensor<T>(std::move(dims)), GenericBase(TensorType<T>, this->rank(), this->dimensions().data()) {
		if (std::distance(first, last) != this->getFlattenedLength()) {
			ErrorManager::throwException(ErrorName::TensorNewError, "Length of data range does not match specified dimensions");
		}
		std::copy(first, last, this->begin());
	}

	template<typename T>
	Tensor<T>::Tensor(GenericBase t) : TypedTensor<T>({t.getDimensions(), t.getRank()}), GenericBase(std::move(t)) {
		if (TensorType<T> != GenericBase::type()) {
			ErrorManager::throwException(ErrorName::TensorTypeError);
		}
	}

	template<typename T>
	Tensor<T>::Tensor(MTensor t, Ownership owner) : Tensor(GenericBase {t, owner}) {}


} /* namespace LLU */

#endif /* LLU_CONTAINERS_TENSOR_H_ */
