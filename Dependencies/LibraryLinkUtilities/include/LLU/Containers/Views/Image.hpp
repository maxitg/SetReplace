/**
 * @file
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief   Definition and implementation of ImageView and ImageTypedView.
 */
#ifndef LLU_CONTAINERS_VIEWS_IMAGE_HPP
#define LLU_CONTAINERS_VIEWS_IMAGE_HPP

#include "LLU/Containers/Generic/Image.hpp"
#include "LLU/Containers/Interfaces.h"
#include "LLU/Containers/Iterators/IterableContainer.hpp"
#include "LLU/ErrorLog/ErrorManager.h"

namespace LLU {

	/**
	 * @brief   Simple, light-weight, non-owning wrappper over MImage.
	 *
	 * Intended for use in functions that only need to access MImage metadata, where it can alleviate the need for introducing template parameters
	 * for MImage passing mode (like in GenericImage) or data type (like in Image class).
	 */
	class ImageView : public ImageInterface {
	public:
		ImageView() = default;

		/**
		 * Create a ImageView from a GenericImage
		 * @param gIm - a GenericImage
		 */
		ImageView(const GenericImage& gIm) : m {gIm.getContainer()} {}	  // NOLINT: implicit conversion to a view is useful and harmless

		/**
		 * Create a ImageView from a raw MImage
		 * @param mi - a raw MImage
		 */
		ImageView(MImage mi) : m {mi} {}	// NOLINT

		/// @copydoc ImageInterface::colorspace()
		colorspace_t colorspace() const override {
			return LibraryData::ImageAPI()->MImage_getColorSpace(m);
		}

		/// @copydoc ImageInterface::rows()
		mint rows() const override {
			return LibraryData::ImageAPI()->MImage_getRowCount(m);
		}

		/// @copydoc ImageInterface::columns()
		mint columns() const override {
			return LibraryData::ImageAPI()->MImage_getColumnCount(m);
		}

		/// @copydoc ImageInterface::slices()
		mint slices() const override {
			return LibraryData::ImageAPI()->MImage_getSliceCount(m);
		}

		/// @copydoc ImageInterface::channels()
		mint channels() const override {
			return LibraryData::ImageAPI()->MImage_getChannels(m);
		}

		/// @copydoc ImageInterface::alphaChannelQ()
		bool alphaChannelQ() const override {
			return LibraryData::ImageAPI()->MImage_alphaChannelQ(m) == True;
		}

		/// @copydoc ImageInterface::interleavedQ()
		bool interleavedQ() const override {
			return LibraryData::ImageAPI()->MImage_interleavedQ(m) == True;
		}

		/// @copydoc ImageInterface::is3D()
		bool is3D() const override {
			return LibraryData::ImageAPI()->MImage_getRank(m) == 3;
		}

		/// @copydoc ImageInterface::getRank()
		mint getRank() const override {
			return LibraryData::ImageAPI()->MImage_getRank(m);
		}

		/// @copydoc ImageInterface::getFlattenedLength()
		mint getFlattenedLength() const override {
			return LibraryData::ImageAPI()->MImage_getFlattenedLength(m);
		}

		/// @copydoc ImageInterface::type()
		imagedata_t type() const final {
			return LibraryData::ImageAPI()->MImage_getDataType(m);
		}

		/// @copydoc ImageInterface::rawData()
		void* rawData() const override {
			return LibraryData::ImageAPI()->MImage_getRawData(m);
		}

	private:
		MImage m = nullptr;
	};

	template<typename T>
	class ImageTypedView : public ImageView, public IterableContainer<T> {
	public:
		ImageTypedView() = default;

		/**
		 * Create a ImageTypedView from a GenericImage.
		 * @param gIm - a GenericImage
		 * @throws ErrorName::ImageTypeError - if the actual datatype of \p gIm is not T
		 */
		ImageTypedView(const GenericImage& gIm) : ImageView(gIm) {	  // NOLINT: implicit conversion to a view is useful and harmless
			if (ImageType<T> != type()) {
				ErrorManager::throwException(ErrorName::ImageTypeError);
			}
		}

		/**
		 * Create a ImageTypedView from a ImageView.
		 * @param iv - a ImageView
		 * @throws ErrorName::ImageTypeError - if the actual datatype of \p iv is not T
		 */
		ImageTypedView(ImageView iv) : ImageView(std::move(iv)) {	 // NOLINT
			if (ImageType<T> != type()) {
				ErrorManager::throwException(ErrorName::ImageTypeError);
			}
		}

		/**
		 * Create a ImageTypedView from a raw MImage.
		 * @param mi - a raw MImage
		 * @throws ErrorName::ImageTypeError - if the actual datatype of \p mi is not T
		 */
		ImageTypedView(MImage mi) : ImageView(mi) {	   // NOLINT
			if (ImageType<T> != type()) {
				ErrorManager::throwException(ErrorName::ImageTypeError);
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
	 * Take a Image-like object \p img and a function \p callable and call the function with a ImageTypedView created from \p img
	 * @tparam  ImageT - a Image-like type (GenericImage, ImageView or MNumericAray)
	 * @tparam  F - any callable object
	 * @param   img - Image-like object on which an operation will be performed
	 * @param   callable - a callable object that can be called with a ImageTypedView of any type
	 * @return  result of calling \p callable on a ImageTypedView over \p img
	 */
	template<typename ImageT, typename F>
	auto asTypedImage(ImageT&& img, F&& callable) {
		switch (img.type()) {
			case MImage_Type_Bit: return std::forward<F>(callable)(ImageTypedView<std::int8_t>(std::forward<ImageT>(img)));
			case MImage_Type_Bit8: return std::forward<F>(callable)(ImageTypedView<std::uint8_t>(std::forward<ImageT>(img)));
			case MImage_Type_Bit16: return std::forward<F>(callable)(ImageTypedView<std::uint16_t>(std::forward<ImageT>(img)));
			case MImage_Type_Real32: return std::forward<F>(callable)(ImageTypedView<float>(std::forward<ImageT>(img)));
			case MImage_Type_Real: return std::forward<F>(callable)(ImageTypedView<double>(std::forward<ImageT>(img)));
			default: ErrorManager::throwException(ErrorName::ImageTypeError);
		}
	}

	/// @cond
	// Specialization of asTypedImage for MImage
	template<typename F>
	auto asTypedImage(MImage img, F&& callable) {
		return asTypedImage(ImageView {img}, std::forward<F>(callable));
	}
	/// @endcond
}  // namespace LLU

#endif	  // LLU_CONTAINERS_VIEWS_IMAGE_HPP
