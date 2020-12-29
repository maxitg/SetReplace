#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

template<typename T>
constexpr T negator = (std::numeric_limits<T>::max)();

template<>
constexpr int8_t negator<int8_t> = 1;

template<>
constexpr float negator<float> = 1.f;

template<>
constexpr double negator<double> = 1.;

struct ImageNegator {
	template<typename T>
	void operator()(LLU::Image<T> in, LLU::MArgumentManager& mngr) {
		LLU::Image<T> out {in.clone()};

		std::transform(std::cbegin(in), std::cend(in), std::begin(out), [](T inElem) { return negator<T> - inElem; });
		mngr.setImage(out);
	}

	template<typename T>
	void operator()(LLU::ImageTypedView<T> imgView) {
		std::for_each(imgView.begin(), imgView.end(), [](T& v) { v = negator<T> - v; });
	}
};

LLU_LIBRARY_FUNCTION(ImageNegate) {
	mngr.operateOnImage<LLU::Passing::Automatic, ImageNegator>(0, mngr);
}

LLU_LIBRARY_FUNCTION(NegateImages) {
	auto imgList = mngr.getDataList<LLU::GenericImage>(0);
	LLU::DataList<LLU::GenericImage> outList;
	for (auto&& node : imgList) {
		auto& img = node.value();
		LLU::asTypedImage(img, ImageNegator{});
		outList.push_back(std::move(img));
	}
	mngr.set(outList);
}