/**
 * @file
 * @brief GenericNumericArray definition and implementation
 */
#ifndef LLU_CONTAINERS_GENERIC_NUMERICARRAY_HPP
#define LLU_CONTAINERS_GENERIC_NUMERICARRAY_HPP

#include "LLU/Containers/Generic/Base.hpp"
#include "LLU/Containers/Interfaces.h"

namespace LLU {

	template<>
	class MContainer<MArgumentType::NumericArray>;

	/// MContainer specialization for MNumericArray is called GenericNumericArray
	using GenericNumericArray = MContainer<MArgumentType::NumericArray>;

	/**
	 *  @brief  MContainer specialization for MNumericArray
	 */
	template<>
	class MContainer<MArgumentType::NumericArray> : public NumericArrayInterface, public MContainerBase<MArgumentType::NumericArray> {
	public:
		/// Inherit constructors from MContainerBase
		using MContainerBase<MArgumentType::NumericArray>::MContainerBase;

		/**
		 * @brief   Default constructor, the MContainer does not manage any instance of MNumericArray.
		 */
		MContainer() = default;

		/**
		 * @brief   Create GenericNumericArray of given type and shape
		 * @param   type - new GenericNumericArray type
		 * @param   rank - new GenericNumericArray rank
		 * @param   dims - new GenericNumericArray dimensions
		 * @see     <http://reference.wolfram.com/language/LibraryLink/ref/callback/MNumericArray_new.html>
		 */
		MContainer(numericarray_data_t type, mint rank, const mint* dims);

		/**
		 * @brief   Convert this object to a new GenericNumericArray of given datatype, using specified conversion method
		 * @param   t - destination data type
		 * @param   method - conversion method
		 * @param   param - conversion method parameter (aka tolerance)
		 * @return  converted GenericNumericArray owned by the Library
		 * @see     <http://reference.wolfram.com/language/LibraryLink/ref/callback/MNumericArray_convertType.html>
		 */
		GenericNumericArray convert(numericarray_data_t t, NA::ConversionMethod method, double param) const;

		/**
		 * @brief   Clone this MContainer, performs a deep copy of the underlying MNumericArray.
		 * @note    The cloned MContainer always belongs to the library (Ownership::Library) because LibraryLink has no idea of its existence.
		 * @return  new MContainer, by value
		 */
		MContainer clone() const {
			return MContainer {cloneContainer(), Ownership::Library};
		}

		/// @copydoc NumericArrayInterface::getRank()
		mint getRank() const override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getRank(this->getContainer());
		}

		/// @copydoc NumericArrayInterface::getDimensions()
		mint const* getDimensions() const override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getDimensions(this->getContainer());
		}

		/// @copydoc NumericArrayInterface::getFlattenedLength()
		mint getFlattenedLength() const override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getFlattenedLength(this->getContainer());
		}

		/// @copydoc NumericArrayInterface::type()
		numericarray_data_t type() const override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getType(this->getContainer());
		}

		/// @copydoc NumericArrayInterface::rawData()
		void* rawData() const noexcept override {
			return LibraryData::NumericArrayAPI()->MNumericArray_getData(this->getContainer());
		}

	private:

		/**
		 *   @brief Make a deep copy of the raw container
		 *   @see   <http://reference.wolfram.com/language/LibraryLink/ref/callback/MNumericArray_clone.html>
		 **/
		Container cloneImpl() const override;

		/**
		 * @copydoc MContainer<MArgumentType::Image>::shareCount()
		 * @see 	<http://reference.wolfram.com/language/LibraryLink/ref/callback/MNumericArray_shareCount.html>
		 */
		mint shareCountImpl() const noexcept override {
			return LibraryData::NumericArrayAPI()->MNumericArray_shareCount(this->getContainer());
		}

		///@copydoc   MContainer<MArgumentType::DataStore>::pass
		void passImpl(MArgument& res) const noexcept override {
			MArgument_setMNumericArray(res, this->getContainer());
		}
	};

}  // namespace LLU

#endif	  // LLU_CONTAINERS_GENERIC_NUMERICARRAY_HPP
