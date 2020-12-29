#include <cstdint>
#include <type_traits>

#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

LLU_LIBRARY_FUNCTION(EchoImage1) {
	mngr.operateOnImage(0, [&mngr](auto im1) {
		using T = typename std::remove_reference_t<decltype(im1)>::value_type;
		auto im2 {std::move(im1)};	  // test move constructor
		LLU::Image<T> im3;
		im3 = std::move(im2);	 // test move assignment
		mngr.setImage(im3);
	});
}

LLU_LIBRARY_FUNCTION(EchoImage2) {
	mngr.operateOnImage(0, [&mngr](auto&& in) {
		auto slices = in.is3D() ? in.slices() : 0;
		auto columns = in.columns();
		auto rows = in.rows();
		auto channels = in.channels();
		auto colorspace = in.colorspace();
		auto interleaving = in.interleavedQ();

		using T = typename std::remove_reference_t<decltype(in)>::value_type;
		LLU::Image<T> out(slices, columns, rows, channels, colorspace, interleaving);

		for (mint column = 1; column <= columns; column++) {
			for (mint row = 1; row <= rows; row++) {
				if (in.is3D()) {
					for (mint slice = 1; slice <= slices; slice++) {
						out.set(slice, row, column, 1, in.get(slice, row, column, 1));
					}
				} else {
					out.set(row, column, 1, in.get(row, column, 1));
				}
			}
		}
		mngr.setImage(out);
	});
}

LLU_LIBRARY_FUNCTION(EchoImage3) {
	auto img = mngr.getGenericImage(0);
	mngr.set(img);
}

LLU_LIBRARY_FUNCTION(ConvertImageToByte) {
	mngr.operateOnImage(0, [&mngr](auto&& in) {
		auto out {in.template convert<std::uint8_t>()};
		mngr.setImage(out);
	});
}

LLU_LIBRARY_FUNCTION(UnifyImageTypes) {
	mngr.operateOnImage(0, [&mngr](auto&& in) {
		using T = typename std::remove_reference_t<decltype(in)>::value_type;
		mngr.operateOnImage(1, [&mngr](auto&& in2) {
			LLU::Image<T> out {in2.template convert<T>()};
			mngr.setImage(out);
		});
	});
}

LLU_LIBRARY_FUNCTION(CloneImage) {
	mngr.operateOnImage(0, [&mngr](auto&& im1) {
		using T = typename std::remove_reference_t<decltype(im1)>::value_type;
		LLU::Image<T> im2 {im1.clone()};
		LLU::Image<T> im3;
		im3 = im2.clone();
		mngr.setImage(im3);
	});
}

LLU_LIBRARY_FUNCTION(EmptyWrapper) {
	LLU::Unused(mngr);
	LLU::Image<std::uint8_t> im {nullptr, LLU::Ownership::Library};	  // this should trigger an exception
}
