/**
 * @file
 * @brief GenericImage definition and implementation
 */
#ifndef LLU_CONTAINERS_GENERIC_IMAGE_HPP
#define LLU_CONTAINERS_GENERIC_IMAGE_HPP

#include "LLU/Containers/Generic/Base.hpp"
#include "LLU/Containers/Interfaces.h"

namespace LLU {

	template<>
	class MContainer<MArgumentType::Image>;

	/// MContainer specialization for MImage is called GenericImage
	using GenericImage = MContainer<MArgumentType::Image>;

	/**
	 *  @brief  MContainer specialization for MImage
	 */
	template<>
	class MContainer<MArgumentType::Image> : public ImageInterface, public MContainerBase<MArgumentType::Image> {
	public:
		/// Inherit constructors from MContainerBase
		using MContainerBase<MArgumentType::Image>::MContainerBase;

		/// Default constructor, the MContainer does not manage any instance of MImage.
		MContainer() = default;

		/**
		 * @brief Create new 2D MImage based on given parameters
		 * @param width - image width in pixels (number of columns)
		 * @param height - image height in pixels (number of rows)
		 * @param channels - number of color channels (for example 3 for RGB, 1 for greyscale)
		 * @param type - image data type (1-bit, 8-bit, Real32, etc.)
		 * @param colorSpace - image color space
		 * @param interleaving - whether the image data should be interleaved or not
		 */
		MContainer(mint width, mint height, mint channels, imagedata_t type, colorspace_t colorSpace, mbool interleaving)
			: MContainer(0, width, height, channels, type, colorSpace, interleaving) {}

		/**
		 * @brief Create new 2D or 3D MImage based on given parameters
		 * @param slices - number of slices (0 for 2D Image, any positive number for Image3D)
		 * @param width - image width in pixels (number of columns)
		 * @param height - image height in pixels (number of rows)
		 * @param channels - number of color channels (for example 3 for RGB, 1 for greyscale)
		 * @param type - image data type (1-bit, 8-bit, Real32, etc.)
		 * @param colorSpace - image color space
		 * @param interleaving - whether the image data should be interleaved or not
		 */
		MContainer(mint slices, mint width, mint height, mint channels, imagedata_t type, colorspace_t colorSpace, mbool interleaving);

		/**
		 * @brief   Convert this object to a new GenericImage of given datatype, optionally changing interleaving
		 * @param   t - destination data type
		 * @param   interleavingQ - whether the converted GenericImage should be interleaved or not
		 * @return  converted GenericImage owned by the Library
		 * @see     <http://reference.wolfram.com/language/LibraryLink/ref/callback/MImage_convertType.html>
		 */
		GenericImage convert(imagedata_t t, mbool interleavingQ) const;

		/**
		 * @brief   Convert this object to a new GenericImage of given datatype
		 * @param   t - destination data type
		 * @return  converted GenericImage owned by the Library
		 * @see     <http://reference.wolfram.com/language/LibraryLink/ref/callback/MImage_convertType.html>
		 */
		GenericImage convert(imagedata_t t) const {
			return convert(t, static_cast<mbool>(interleavedQ()));
		}

		/**
		 * @brief   Clone this MContainer, performs a deep copy of the underlying MImage.
		 * @note    The cloned MContainer always belongs to the library (Ownership::Library) because LibraryLink has no idea of its existence.
		 * @return  new MContainer, by value
		 */
		MContainer clone() const {
			return MContainer {cloneContainer(), Ownership::Library};
		}

		/// @copydoc ImageInterface::colorspace()
		colorspace_t colorspace() const override {
			return LibraryData::ImageAPI()->MImage_getColorSpace(this->getContainer());
		}

		/// @copydoc ImageInterface::rows()
		mint rows() const override {
			return LibraryData::ImageAPI()->MImage_getRowCount(this->getContainer());
		}

		/// @copydoc ImageInterface::columns()
		mint columns() const override {
			return LibraryData::ImageAPI()->MImage_getColumnCount(this->getContainer());
		}

		/// @copydoc ImageInterface::slices()
		mint slices() const override {
			return LibraryData::ImageAPI()->MImage_getSliceCount(this->getContainer());
		}

		/// @copydoc ImageInterface::channels()
		mint channels() const override {
			return LibraryData::ImageAPI()->MImage_getChannels(this->getContainer());
		}

		/// @copydoc ImageInterface::alphaChannelQ()
		bool alphaChannelQ() const override {
			return LibraryData::ImageAPI()->MImage_alphaChannelQ(this->getContainer()) != 0;
		}

		/// @copydoc ImageInterface::interleavedQ()
		bool interleavedQ() const override {
			return LibraryData::ImageAPI()->MImage_interleavedQ(this->getContainer()) != 0;
		}

		/// @copydoc ImageInterface::is3D()
		bool is3D() const override {
			return LibraryData::ImageAPI()->MImage_getRank(this->getContainer()) == 3;
		}

		/// @copydoc ImageInterface::getRank()
		mint getRank() const override {
			return LibraryData::ImageAPI()->MImage_getRank(this->getContainer());
		}

		/// @copydoc ImageInterface::getFlattenedLength()
		mint getFlattenedLength() const override {
			return LibraryData::ImageAPI()->MImage_getFlattenedLength(this->getContainer());
		}

		/// @copydoc ImageInterface::type()
		imagedata_t type() const override {
			return LibraryData::ImageAPI()->MImage_getDataType(this->getContainer());
		}

		/// @copydoc ImageInterface::rawData()
		void* rawData() const override {
			return LibraryData::ImageAPI()->MImage_getRawData(this->getContainer());
		}
	private:

		/**
		 *   @brief     Make a deep copy of the raw container
		 *   @see 		<http://reference.wolfram.com/language/LibraryLink/ref/callback/MImage_clone.html>
		 **/
		Container cloneImpl() const override;

		/**
		 * @brief Return share count of internal container, if present and 0 otherwise
		 * @see 	<http://reference.wolfram.com/language/LibraryLink/ref/callback/MImage_shareCount.html>
		 */
		mint shareCountImpl() const noexcept override {
			return LibraryData::ImageAPI()->MImage_shareCount(this->getContainer());
		}

		/// @copydoc   MContainer<MArgumentType::DataStore>::pass
		void passImpl(MArgument& res) const noexcept override {
			MArgument_setMImage(res, this->getContainer());
		}
	};

}  // namespace LLU

#endif	  // LLU_CONTAINERS_GENERIC_IMAGE_HPP
