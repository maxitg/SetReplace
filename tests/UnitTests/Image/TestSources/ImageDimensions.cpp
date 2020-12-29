#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

using LLU::ImageView;

LIBRARY_LINK_FUNCTION(ImageColumnCount) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(libData, Argc, Args, Res);
		auto image = mngr.getGenericImage(0);
		mngr.setInteger(image.columns());
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLU::ErrorCode::FunctionError;
	}
	return err;
}

LIBRARY_LINK_FUNCTION(ImageRank) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(libData, Argc, Args, Res);
		mngr.operateOnImage(0, [&mngr](auto&& image) { mngr.setInteger(image.rank()); });
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLU::ErrorCode::FunctionError;
	}
	return err;
}

auto getLargest(const std::vector<ImageView>& imgs) {
	return std::max_element(std::cbegin(imgs), std::cend(imgs), [](const ImageView& img1, const ImageView& img2) {
		return img1.getFlattenedLength() < img2.getFlattenedLength();
	});
}

LLU_LIBRARY_FUNCTION(GetLargest) {
	auto imgAuto = mngr.getImage<float>(0);
	auto imgConstant = mngr.getGenericImage<LLU::Passing::Constant>(1);
	auto imgManual = mngr.getImage<float, LLU::Passing::Manual>(2);
	std::vector<ImageView> imgs {ImageView {imgAuto}, ImageView {imgConstant}, ImageView {imgManual}};
	auto largest = getLargest(imgs);
	mngr.set(static_cast<mint>(std::distance(std::cbegin(imgs), largest)));

	// perform some random assignments and copies to see it they compile
	std::swap(imgs[0], imgs[1]);
	ImageView iv = std::move(imgs[2]);
	imgs[2] = iv;
}

LIBRARY_LINK_FUNCTION(ImageRowCount) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(libData, Argc, Args, Res);
		auto image = mngr.getGenericImage(0);
		mngr.setInteger(image.rows());
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLU::ErrorCode::FunctionError;
	}
	return err;
}

LLU_LIBRARY_FUNCTION(EmptyView) {
	ImageView v;
	LLU::Tensor<mint> t {v.slices(), v.rows(), v.columns(), static_cast<mint>(v.colorspace()), static_cast<mint>(v.type())};
	mngr.set(t);
}