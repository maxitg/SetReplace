/**
 * @file	Image.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	18/04/2017
 *
 * @brief	Template specializations of Image::type attribute for all data types that we want to support
 *
 */
#include <cstdint>

#include "LLU/Containers/Generic/Image.hpp"
#include "LLU/Containers/Image.h"

namespace LLU {

	MContainer<MArgumentType::Image>::MContainer(mint slices, mint width, mint height, mint channels, imagedata_t type, colorspace_t colorSpace,
												 mbool interleaving) {
		Container tmp {};
		bool is3DImage = (slices != 0);
		if (0 != (is3DImage ? LibraryData::ImageAPI()->MImage_new3D(slices, width, height, channels, type, colorSpace, interleaving, &tmp)
							: LibraryData::ImageAPI()->MImage_new2D(width, height, channels, type, colorSpace, interleaving, &tmp))) {
			ErrorManager::throwException(ErrorName::ImageNewError);
		}
		this->reset(tmp);
	}

	GenericImage GenericImage::convert(imagedata_t t, mbool interleavingQ) const {
		auto* newImage = LibraryData::ImageAPI()->MImage_convertType(this->getContainer(), t, interleavingQ);
		if (!newImage) {
			ErrorManager::throwException(ErrorName::ImageNewError, "Conversion to type " + std::to_string(static_cast<int>(t)) + " failed.");
		}
		return {newImage, Ownership::Library};
	}

	auto GenericImage::cloneImpl() const -> Container {
		Container tmp {};
		if (0 != LibraryData::ImageAPI()->MImage_clone(this->getContainer(), &tmp)) {
			ErrorManager::throwException(ErrorName::ImageCloneError);
		}
		return tmp;
	}

	/// @cond
	//
	//	Template specializations for Bit images
	//

	template<>
	int8_t TypedImage<int8_t>::getValueAt(mint* position, mint channel) const {
		raw_t_bit res {};
		if (0 != LibraryData::ImageAPI()->MImage_getBit(this->getInternal(), position, channel, &res)) {
			this->indexError();
		}
		return res;
	}

	template<>
	void TypedImage<int8_t>::setValueAt(mint* position, mint channel, int8_t newValue) {
		if (0 != LibraryData::ImageAPI()->MImage_setBit(this->getInternal(), position, channel, newValue)) {
			this->indexError();
		}
	}

	//
	//	Template specializations for Byte images
	//

	template<>
	uint8_t TypedImage<uint8_t>::getValueAt(mint* position, mint channel) const {
		raw_t_ubit8 res {};
		if (0 != LibraryData::ImageAPI()->MImage_getByte(this->getInternal(), position, channel, &res)) {
			this->indexError();
		}
		return res;
	}

	template<>
	void TypedImage<uint8_t>::setValueAt(mint* position, mint channel, uint8_t newValue) {
		if (0 != LibraryData::ImageAPI()->MImage_setByte(this->getInternal(), position, channel, newValue)) {
			this->indexError();
		}
	}

	//
	//	Template specializations for Bit16 images
	//

	template<>
	uint16_t TypedImage<uint16_t>::getValueAt(mint* position, mint channel) const {
		raw_t_ubit16 res {};
		if (0 != LibraryData::ImageAPI()->MImage_getBit16(this->getInternal(), position, channel, &res)) {
			this->indexError();
		}
		return res;
	}

	template<>
	void TypedImage<uint16_t>::setValueAt(mint* position, mint channel, uint16_t newValue) {
		if (0 != LibraryData::ImageAPI()->MImage_setBit16(this->getInternal(), position, channel, newValue)) {
			this->indexError();
		}
	}

	//
	//	Template specializations for Real32 images
	//

	template<>
	float TypedImage<float>::getValueAt(mint* position, mint channel) const {
		raw_t_real32 res {};
		if (0 != LibraryData::ImageAPI()->MImage_getReal32(this->getInternal(), position, channel, &res)) {
			this->indexError();
		}
		return res;
	}

	template<>
	void TypedImage<float>::setValueAt(mint* position, mint channel, float newValue) {
		if (0 != LibraryData::ImageAPI()->MImage_setReal32(this->getInternal(), position, channel, newValue)) {
			this->indexError();
		}
	}

	//
	//	Template specializations for Real images
	//

	template<>
	double TypedImage<double>::getValueAt(mint* position, mint channel) const {
		raw_t_real64 res {};
		if (0 != LibraryData::ImageAPI()->MImage_getReal(this->getInternal(), position, channel, &res)) {
			this->indexError();
		}
		return res;
	}

	template<>
	void TypedImage<double>::setValueAt(mint* position, mint channel, double newValue) {
		if (0 != LibraryData::ImageAPI()->MImage_setReal(this->getInternal(), position, channel, newValue)) {
			this->indexError();
		}
	}
	/// @endcond
} /* namespace LLU */
