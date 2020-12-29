/**
 * @file
 * @brief   GenericTensor definition and implementation
 */

#ifndef LLU_CONTAINERS_GENERIC_TENSOR_HPP
#define LLU_CONTAINERS_GENERIC_TENSOR_HPP

#include "LLU/Containers/Generic/Base.hpp"
#include "LLU/Containers/Interfaces.h"

namespace LLU {

	template<>
	class MContainer<MArgumentType::Tensor>;

	/// MContainer specialization for MTensor is called GenericTensor
	using GenericTensor = MContainer<MArgumentType::Tensor>;
	
	/**
	 *  @brief  MContainer specialization for MTensor
	 */
	template<>
	class MContainer<MArgumentType::Tensor> : public TensorInterface, public MContainerBase<MArgumentType::Tensor> {
	public:
		/// Inherit constructors from MContainerBase
		using MContainerBase<MArgumentType::Tensor>::MContainerBase;

		/// Default constructor, the MContainer does not manage any instance of MTensor.
		MContainer() = default;

		/**
		 * @brief   Create GenericTensor of given type and shape
		 * @param   type - new GenericTensor type (MType_Integer, MType_Real or MType_Complex)
		 * @param   rank - new GenericTensor rank
		 * @param   dims - new GenericTensor dimensions
		 * @see     <http://reference.wolfram.com/language/LibraryLink/ref/callback/MTensor_new.html>
		 */
		MContainer(mint type, mint rank, const mint* dims);

		/**
		 * @brief   Clone this MContainer, performs a deep copy of the underlying MTensor.
		 * @note    The cloned MContainer always belongs to the library (Ownership::Library) because LibraryLink has no idea of its existence.
		 * @return  new MContainer, by value
		 */
		MContainer clone() const {
			return MContainer {cloneContainer(), Ownership::Library};
		}

		/// @copydoc TensorInterface::getRank()
		mint getRank() const override {
			return LibraryData::API()->MTensor_getRank(this->getContainer());
		}

		/// @copydoc TensorInterface::getDimensions()
		mint const* getDimensions() const override {
			return LibraryData::API()->MTensor_getDimensions(this->getContainer());
		}

		/// @copydoc TensorInterface::getFlattenedLength()
		mint getFlattenedLength() const override {
			return LibraryData::API()->MTensor_getFlattenedLength(this->getContainer());
		}

		/// @copydoc TensorInterface::type()
		mint type() const override {
			return LibraryData::API()->MTensor_getType(this->getContainer());
		}

		/// @copydoc TensorInterface::rawData()
		void* rawData() const override;

	private:

		/**
		 * @copydoc MContainer<MArgumentType::Image>::shareCount()
		 * @see 	<http://reference.wolfram.com/language/LibraryLink/ref/callback/MTensor_shareCount.html>
		 */
		mint shareCountImpl() const noexcept override {
			return LibraryData::API()->MTensor_shareCount(this->getContainer());
		}

		/// @copydoc   MContainer<MArgumentType::DataStore>::pass
		void passImpl(MArgument& res) const noexcept override {
			MArgument_setMTensor(res, this->getContainer());
		}

		/**
		 *   @brief   Make a deep copy of the raw container
		 *   @see 		<http://reference.wolfram.com/language/LibraryLink/ref/callback/MTensor_clone.html>
		 **/
		Container cloneImpl() const override;
	};

}  // namespace LLU

#endif	  // LLU_CONTAINERS_GENERIC_TENSOR_HPP
