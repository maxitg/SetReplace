/**
 * @file
 * @brief
 */

#ifndef LLU_CONTAINERS_MARRAYDIMENSIONS_H_
#define LLU_CONTAINERS_MARRAYDIMENSIONS_H_

#include <initializer_list>
#include <type_traits>
#include <vector>

#include "LLU/ErrorLog/ErrorManager.h"
#include "LLU/LibraryData.h"
#include "LLU/Utilities.hpp"

namespace LLU {

	/**
	 * @class MArrayDimensions
	 * @brief Helper class that carries meta-information about container's size and dimensions.
	 */
	class MArrayDimensions {
	public:
		/**
		 *	@brief Default constructor
		 **/
		MArrayDimensions() = default;

		/**
		 * 	@brief		Constructs MArrayDimensions from a list of dimensions
		 *	@param[in]	dimensions - list of MArray dimensions
		 *	@throws		ErrorName::DimensionsError - if \c dims are invalid
		 *	@throws		ErrorName::FunctionError - if any of Wolfram*Library structures was not initialized
		 **/
		MArrayDimensions(std::initializer_list<mint> dimensions);

		/**
		 * 	@brief		Constructs MArrayDimensions from a C-style list (raw pointer + length)
		 *	@param[in]	dimensions - pointer to the memory where consecutive dimensions are stored
		 *	@param[in]	rank - length of the \p dims array
		 *	@throws		ErrorName::DimensionsError - if \c dims are invalid
		 *	@throws		ErrorName::FunctionError - if any of Wolfram*Library structures was not initialized
		 **/
		template<typename T, typename = typename std::enable_if_t<std::is_integral_v<T>>>
		MArrayDimensions(const T* dimensions, mint rank);

		/**
		 * 	@brief		Constructs MArrayDimensions from a vector of dimensions
		 *	@param[in]	dimensions - vector with MArray dimensions
		 *	@throws		ErrorName::DimensionsError - if \c dims are invalid
		 *	@throws		ErrorName::FunctionError - if any of Wolfram*Library structures was not initialized
		 **/
		template<typename T, typename = typename std::enable_if_t<std::is_integral_v<T>>>
		explicit MArrayDimensions(const std::vector<T>& dimensions);

		/**
		 * @brief   Create new dimensions from a range
		 * @tparam  InputIter - any type that is an input iterator
		 * @param   dimsBegin - range begin
		 * @param   dimsEnd - range end
		 */
		template<typename InputIter, typename = enable_if_input_iterator<InputIter>>
		MArrayDimensions(InputIter dimsBegin, InputIter dimsEnd);

		/**
		 *	@brief Get container rank
		 **/
		mint rank() const noexcept {
			return static_cast<mint>(dims.size());
		}

		/**
		 *	@brief Get raw pointer to container dimensions
		 **/
		const mint* data() const noexcept {
			return dims.data();
		}

		/**
		 *	@brief Get container dimensions in the form of const& to \b std::vector
		 **/
		const std::vector<mint>& get() const noexcept {
			return dims;
		}

		/**
		 *	@brief 		Get single dimension
		 *	@param[in]	dim - index of desired dimension
		 *	@throws		indexError() - if \c dim is out-of-bounds
		 **/
		mint get(mint dim) const {
			if (dim >= rank() || dim < 0) {
				ErrorManager::throwException(ErrorName::MArrayDimensionIndexError, dim);
			}
			return dims[static_cast<decltype(dims)::size_type>(dim)];
		}

		/**
		 *	@brief 		Convert coordinates of an element in a multidimensional MArray to the corresponding index in a flat list of elements
		 *	@param[in]	indices - vector with coordinates of desired data element
		 **/
		mint getIndex(const std::vector<mint>& indices) const;

		/**
		 *	@brief 		Check if given coordinates are valid for this container
		 *	@param[in]	indices - vector with coordinates of desired data element
		 *	@throws		indexError() - if \c indices are out-of-bounds
		 **/
		mint getIndexChecked(const std::vector<mint>& indices) const;

		/**
		 * @brief   Check if given index is valid i.e. it does not exceed container bounds
		 * @param   index - index of the desired element
		 * @return  index if it is valid, otherwise an exception is thrown
		 */
		mint getIndexChecked(mint index) const;

		/**
		 *  @brief  Get total number of elements
		 * @return  flattened length of the container
		 */
		mint flatCount() const noexcept {
			return flattenedLength;
		}

	private:
		/// Total number of elements in the container
		mint flattenedLength = 0;

		/// Container dimensions
		std::vector<mint> dims;

		/// This helps to convert coordinates \f$ (x_1, \ldots, x_n) \f$ in multidimensional MArray to the corresponding index in a flat list of elements
		std::vector<mint> offsets;

		/// Populate \c offsets member
		void fillOffsets();

	private:
		/**
		 *	@brief 		Check if container size will fit into \b mint
		 *	@param[in]	s - container size
		 *	@throws		ErrorName::DimensionsError - if \c v is too big
		 **/
		template<typename T>
		mint checkContainerSize(T s) const;

		/// Calculate total array length based on current value of dims
		[[nodiscard]] mint totalLengthFromDims() const noexcept;
	};

	template<typename T, typename>
	MArrayDimensions::MArrayDimensions(const T* dimensions, mint rank) : MArrayDimensions(dimensions, std::next(dimensions, rank)) {}

	template<typename T, typename>
	MArrayDimensions::MArrayDimensions(const std::vector<T>& dimensions) : MArrayDimensions(std::cbegin(dimensions), std::cend(dimensions)) {}

	template<typename InputIter, typename>
	MArrayDimensions::MArrayDimensions(InputIter dimsBegin, InputIter dimsEnd) {
		mint depth = checkContainerSize(std::distance(dimsBegin, dimsEnd));
		auto dimsOk = std::all_of(dimsBegin, dimsEnd - 1, [](auto d) { return (d > 0) && (d <= (std::numeric_limits<mint>::max)()); }) &&
					  (dimsBegin[depth - 1] >= 0) && (dimsBegin[depth - 1] <= (std::numeric_limits<mint>::max)());
		if (!dimsOk) {
			ErrorManager::throwExceptionWithDebugInfo(ErrorName::DimensionsError, "Invalid input vector with array dimensions");
		}
		dims.reserve(depth);
		std::copy(dimsBegin, dimsEnd, std::back_inserter(dims));
		flattenedLength = totalLengthFromDims();
		fillOffsets();
	}

	template<typename T>
	mint MArrayDimensions::checkContainerSize(T s) const {
		if (s <= 0 || static_cast<std::uint64_t>(s) > static_cast<std::uint64_t>((std::numeric_limits<mint>::max)())) {
			ErrorManager::throwException(ErrorName::DimensionsError);
		}
		return static_cast<mint>(s);
	}

} /* namespace LLU */

#endif /* LLU_CONTAINERS_MARRAYDIMENSIONS_H_ */
