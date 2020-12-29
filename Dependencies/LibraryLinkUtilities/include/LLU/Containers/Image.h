/**
 * @file	Image.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	18/04/2017
 *
 * @brief	Templated C++ wrapper for MImage
 *
 */
#ifndef LLU_CONTAINERS_IMAGE_H_
#define LLU_CONTAINERS_IMAGE_H_

#include <array>

#include "LLU/Containers/Generic/Image.hpp"
#include "LLU/Containers/MArray.hpp"

namespace LLU {

	/**
	 *  @brief  Typed interface for Image.
	 *
	 *  Provides iterators, data access and info about dimensions.
	 *  @tparam T - type of data in Image
	 */
	template<typename T>
	class TypedImage : public MArray<T> {
	public:
		using MArray<T>::MArray;

		/**
		 *   @brief         Get channel value at specified position in 2D image
		 *   @param[in]     row - pixel row (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     col - pixel column (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     channel - desired channel (in Mathematica-style indexing - starting from 1)
		 *   @throws		ErrorName::ImageIndexError - if the specified coordinates are out-of-bound
		 **/
		T get(mint row, mint col, mint channel) const {
			std::array<mint, 2> pos {{row, col}};
			return getValueAt(pos.data(), channel);
		}

		/**
		 *   @brief         Get channel value at specified position in 3D image
		 *   @param[in]		slice - slice index (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     row - pixel row (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     col - pixel column (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     channel - desired channel (in Mathematica-style indexing - starting from 1)
		 *   @throws		ErrorName::ImageIndexError - if the specified coordinates are out-of-bound
		 **/
		T get(mint slice, mint row, mint col, mint channel) const {
			std::array<mint, 3> pos {{slice, row, col}};
			return getValueAt(pos.data(), channel);
		}

		/**
		 *   @brief         Set channel value at specified position in 2D image
		 *   @param[in]     row - pixel row (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     col - pixel column (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     channel - desired channel (in Mathematica-style indexing - starting from 1)
		 *   @param[in]		newValue - new channel value
		 *   @throws		ErrorName::ImageIndexError - if the specified coordinates are out-of-bound
		 **/
		void set(mint row, mint col, mint channel, T newValue) {
			std::array<mint, 2> pos {{row, col}};
			setValueAt(pos.data(), channel, newValue);
		}

		/**
		 *   @brief         Set channel value at specified position in 3D image
		 *   @param[in]		slice - slice index (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     row - pixel row (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     col - pixel column (in Mathematica-style indexing - starting from 1)
		 *   @param[in]     channel - desired channel (in Mathematica-style indexing - starting from 1)
		 *   @param[in]		newValue - new channel value
		 *   @throws		ErrorName::ImageIndexError - if the specified coordinates are out-of-bound
		 **/
		void set(mint slice, mint row, mint col, mint channel, T newValue) {
			std::array<mint, 3> pos {{slice, row, col}};
			setValueAt(pos.data(), channel, newValue);
		}

	private:
		/**
		 * @brief   Get a raw pointer to underlying data
		 * @return  raw pointer to values of type \p T - channel values of the Image
		 * @see     <http://reference.wolfram.com/language/LibraryLink/ref/callback/MImage_getRawData.html>
		 */
		T* getData() const noexcept override {
			return static_cast<T*>(LibraryData::ImageAPI()->MImage_getRawData(this->getInternal()));
		}

		/// Get the raw MImage, must be implemented in subclasses.
		virtual MImage getInternal() const = 0;

		/// Throw Image-specific error for accessing data under invalid index
		[[noreturn]] void indexError() const {
			ErrorManager::throwException(ErrorName::ImageIndexError);
		}

		/**
		 * @brief   Get specified pixel value
		 * @param   pos - coordinates of the pixel in the image
		 * @param   channel - index of the desired value within the pixel
		 * @return  value of the given channel of specified pixel
		 */
		T getValueAt(mint* pos, mint channel) const;

		/**
		 * @brief   Set new channel value for specific pixel in the image
		 * @param   pos - coordinates of the pixel in the image
		 * @param   channel - index of the desired value within the pixel
		 * @param   newValue - new value for the specified channel
		 */
		void setValueAt(mint* pos, mint channel, T newValue);
	};

	/**
	 * @class Image
	 * @brief This is a class template, where template parameter T is the type of data elements. Image is derived from MArray.
	 *
	 * Image<> classes automate creation and deletion of MImages.
	 * They are strongly typed (no void* to underlying memory) and almost all functions from \<algorithms\> can be used on Image.
	 *
	 * @tparam	T - type of underlying data
	 */
	template<typename T>
	class Image : public TypedImage<T>, public GenericImage {
	public:
		/**
		 *   @brief         Constructs new 2D Image
		 *   @param[in]     w - Image width (number of columns)
		 *   @param[in]     h - Image height (number of rows)
		 *   @param[in]     channels - number of channels
		 *   @param[in]     cs - color space
		 *   @param[in]		interleavingQ - whether Image data should be interleaved
		 **/
		Image(mint w, mint h, mint channels, colorspace_t cs, bool interleavingQ);

		/**
		 *   @brief         Constructs new 3D Image
		 *   @param[in]     nFrames - number of 2D frames/slices
		 *   @param[in]     w - Image width (number of columns)
		 *   @param[in]     h - Image height (number of rows)
		 *   @param[in]     channels - number of channels
		 *   @param[in]     cs - color space
		 *   @param[in]     interleavingQ - whether Image data should be interleaved
		 *   @throws		ErrorName::ImageNewError - if internal MImage creation failed
		 **/
		Image(mint nFrames, mint w, mint h, mint channels, colorspace_t cs, bool interleavingQ);

		/**
		 *   @brief         Create new Image from a GenericImage
		 *   @param[in]     im - generic image to be wrapped into Image class
		 *   @throws		ErrorName::ImageTypeError - if the Image template type \b T does not match the actual data type of the generic image
		 **/
		explicit Image(GenericImage im);

		/**
		 *   @brief         Constructs Image based on MImage
		 *   @param[in]     mi - LibraryLink structure to be wrapped
		 *   @param[in]     owner - who manages the memory the raw MImage
		 *   @throws		ErrorName::ImageTypeError - if template parameter \b T does not match MImage data type
		 *   @throws		ErrorName::ImageSizeError - if constructor failed to calculate image dimensions properly
		 **/
		Image(MImage mi, Ownership owner) : Image(GenericImage(mi, owner)) {};

		/// Default constructor - creates an empty wrapper
		Image() = default;

		/**
		 * @brief   Clone this Image, performing a deep copy of the underlying MImage.
		 * @note    The cloned MImage always belongs to the library (Ownership::Library) because LibraryLink has no idea of its existence.
		 * @return  new Image
		 */
		Image clone() const;

		/**
		 *   @brief     Copy this image with type conversion and explicitly specified interleaving
		 *   @tparam    U - any type that Image supports
		 *   @param[in] interleaved - whether the newly created Image should be interleaved
		 *   @return    newly created Image of type U and specified interleaving
		 **/
		template<typename U>
		Image<U> convert(bool interleaved) const;

		/**
		 *   @brief     Copy this image with type conversion and other properties (dimensions, interleaving, color space, etc.) untouched
		 *   @tparam    U - any type that Image supports
		 *   @return    newly created Image of type U
		 **/
		template<typename U>
		Image<U> convert() const;

	private:
		using GenericBase = GenericImage;

		/// @copydoc MContainerBase::getContainer()
		MImage getInternal() const noexcept override {
			return this->getContainer();
		}

		/// Throw Image-specific exception for size-related errors
		[[noreturn]] static void sizeError() {
			ErrorManager::throwException(ErrorName::ImageSizeError);
		}

		/**
		 * @brief   Helper function that extracts dimension information from GenericImage
		 * @param   im - generic image
		 * @return  MArrayDimensions object with dimensions extracted from the input GenericImage
		 */
		static MArrayDimensions dimensionsFromGenericImage(const GenericBase& im);
	};

	template<typename T>
	Image<T>::Image(mint w, mint h, mint channels, colorspace_t cs, bool interleavingQ) : Image(0, w, h, channels, cs, interleavingQ) {}

	template<typename T>
	Image<T>::Image(GenericBase im) : TypedImage<T>(dimensionsFromGenericImage(im)), GenericBase(std::move(im)) {
		if (ImageType<T> != GenericBase::type()) {
			ErrorManager::throwException(ErrorName::ImageTypeError);
		}
	}

	template<typename T>
	Image<T>::Image(mint nFrames, mint w, mint h, mint channels, colorspace_t cs, bool interleavingQ)
		: Image(GenericBase {nFrames, w, h, channels, ImageType<T>, cs, interleavingQ}) {}

	template<typename T>
	Image<T> Image<T>::clone() const {
		return Image {cloneContainer(), Ownership::Library};
	}

	template<typename T>
	template<typename U>
	Image<U> Image<T>::convert(bool interleaved) const {
		return Image<U> {GenericImage::convert(ImageType<U>, interleaved)};
	}

	template<typename T>
	template<typename U>
	Image<U> Image<T>::convert() const {
		return convert<U>(interleavedQ());
	}

	template<typename T>
	MArrayDimensions Image<T>::dimensionsFromGenericImage(const GenericBase& im) {
		std::vector<mint> dims;
		if (!im.getContainer()) {
			return MArrayDimensions {dims};
		}
		mint depth = im.getRank() + (im.channels() == 1 ? 0 : 1);
		if (im.is3D()) {
			dims = {im.slices(), im.rows(), im.columns()};
		} else {
			dims = {im.rows(), im.columns()};
		}
		if (im.channels() > 1) {
			if (im.interleavedQ()) {
				dims.push_back(im.channels());
			} else {
				dims.insert(dims.begin(), im.channels());
			}
		}
		if (dims.size() != static_cast<std::make_unsigned_t<mint>>(depth)) {
			sizeError();
		}
		return MArrayDimensions {dims};
	}
} /* namespace LLU */

#endif /* LLU_CONTAINERS_IMAGE_H_ */
