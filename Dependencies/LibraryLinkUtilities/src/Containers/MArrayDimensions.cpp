/**
 * @file
 * Definitions of non-template member functions and static data members from MArrayDimensions class
 */

#include "LLU/Containers/MArrayDimensions.h"

#include <algorithm>
#include <limits>
#include <numeric>

namespace {
	/**
	 *	@brief 		Check if initializer list size will fit into \b mint
	 *	@param[in]	v - an initializer list
	 *	@throws		ErrorName::DimensionsError - if \c v is too big
	 **/
	void checkInitializerListSize(std::initializer_list<mint> v) {
		if (v.size() <= 0 || v.size() > static_cast<decltype(v)::size_type>((std::numeric_limits<mint>::max)())) {
			LLU::ErrorManager::throwException(LLU::ErrorName::DimensionsError);
		}
	}

	[[noreturn]] void indexError(mint index) {
		LLU::ErrorManager::throwException(LLU::ErrorName::MArrayElementIndexError, index);
	}

}  // namespace

namespace LLU {

	MArrayDimensions::MArrayDimensions(std::initializer_list<mint> dimensions) {
		dims = dimensions;
		checkInitializerListSize(dimensions);
		flattenedLength = totalLengthFromDims();
		fillOffsets();
	}

	void MArrayDimensions::fillOffsets() {
		offsets.assign(dims.size(), 1);
		if (rank() >= 2) {
			std::transform(std::rbegin(offsets), std::rend(offsets) - 1, std::crbegin(dims), std::rbegin(offsets) + 1,
						   [](auto off, auto dim) { return off * dim; });
		}
	}

	mint MArrayDimensions::getIndexChecked(const std::vector<mint>& indices) const {
		if (indices.size() > dims.size()) {
			ErrorManager::throwException(ErrorName::MArrayDimensionIndexError, static_cast<wsint64>(indices.size()));
		}
		auto dimsIt = dims.cbegin();
		for (auto idx : indices) {
			if (idx < 0 || idx >= *dimsIt++) {
				indexError(idx);
			}
		}
		return getIndex(indices);
	}

	mint MArrayDimensions::getIndexChecked(mint index) const {
		if (index < 0 || index >= flatCount()) {
			indexError(index);
		}
		return index;
	}

	mint MArrayDimensions::getIndex(const std::vector<mint>& indices) const {
		mint flatIndex = 0;
		auto offset = offsets.cbegin();
		for (auto idx : indices) {
			flatIndex += idx * (*offset++);
		}
		return flatIndex;
	}

	mint MArrayDimensions::totalLengthFromDims() const noexcept {
		return std::accumulate(std::begin(dims), std::end(dims), static_cast<mint>(1), std::multiplies<>());
	}

} /* namespace LLU */
