/**
 * @file	Basic.cpp
 * @brief
 */

#include <numeric>

#include <LLU/Containers/Tensor.h>
#include <LLU/Containers/Views/Tensor.hpp>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/MArgumentManager.h>

using LLU::Tensor;

LLU_LIBRARY_FUNCTION(CreateMatrix) {
	auto rows = mngr.getInteger<mint>(0);
	auto cols = mngr.getInteger<mint>(1);

	Tensor<mint> out(0, {rows, cols});

	mint count = 1;
	for (auto& elem : out) {
		elem = count++;
	}

	mngr.setTensor(out);
}

LLU_LIBRARY_FUNCTION(CreateEmptyVector) {
	Tensor<mint> out(0, {0});
	mngr.setTensor(out);
}

LLU_LIBRARY_FUNCTION(CreateEmptyMatrix) {
	Tensor<mint> out(0, {3, 5, 0});
	mngr.setTensor(out);
}

// clone Tensor
LLU_LIBRARY_FUNCTION(CloneTensor) {
	mngr.operateOnTensor(0, [&mngr](auto&& t1) {
		using T = typename std::decay_t<decltype(t1)>::value_type;
		Tensor<T> t2 {t1.clone()};
		Tensor<T> t3;
		t3 = t2.clone();
		mngr.setTensor(t3);
	});
}

LLU_LIBRARY_FUNCTION(TestDimensions) {
	auto dims = mngr.getTensor<mint, LLU::Passing::Manual>(0);
	Tensor<double> na(0.0, LLU::MArrayDimensions {dims.begin(), dims.end()});
	mngr.setTensor(na);
}

LLU_LIBRARY_FUNCTION(TestDimensions2) {
	LLU::DataList<LLU::GenericTensor> naList;

	std::vector<std::vector<mint>> dimsList {{0}, {3}, {3, 0}, {3, 2}, {3, 2, 0}, {3, 2, 4}};

	for (auto& dims : dimsList) {
		Tensor<double> na(0.0, LLU::MArrayDimensions {dims});
		naList.push_back(std::move(na));
	}

	mngr.setDataList(naList);
}

LLU_LIBRARY_FUNCTION(EchoTensor) {
	mngr.operateOnTensor(0, [&mngr](auto t1) {
		using T = typename std::decay_t<decltype(t1)>::value_type;
		auto t2 {std::move(t1)};	// test move constructor
		Tensor<T> t3;
		t3 = std::move(t2);	   // test move assignment
		mngr.setTensor(t3);
	});
}

LIBRARY_LINK_FUNCTION(EchoFirst) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	auto t = mngr.getTensor<mint>(0);
	mngr.setInteger(t.front());

	return LLU::ErrorCode::NoError;
}

LIBRARY_LINK_FUNCTION(EchoLast) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	auto t = mngr.getTensor<mint>(0);
	mngr.setInteger(t.back());

	return LLU::ErrorCode::NoError;
}

LLU_LIBRARY_FUNCTION(EchoElement) {
	auto na = mngr.getNumericArray<std::int64_t>(0);
	auto coords = mngr.getTensor<mint>(1);
	std::vector<mint> coordsVec(coords.begin(), coords.end());
	mngr.setInteger(na.at(coordsVec));
}

LLU_LIBRARY_FUNCTION(IntegerMatrixTranspose) {
	auto t = mngr.getTensor<mint>(0);
	Tensor<mint> out(0, {t.dimension(1), t.dimension(0)});

	/* Set the elements of the output matrix */
	for (mint row = 0; row < out.dimension(0); row++) {
		for (mint col = 0; col < out.dimension(1); col++) {
			out[{row, col}] = t[{col, row}];
		}
	}
	mngr.setTensor(out);
}

LLU_LIBRARY_FUNCTION(MeanValue) {
	auto t = mngr.getTensor<double>(0);

	auto total = std::accumulate(t.begin(), t.end(), 0.0);

	auto result = total / t.size();
	mngr.setReal(result);
}

LIBRARY_LINK_FUNCTION(FromVector) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);

	std::vector<mint> v {3, 5, 7, 9};
	Tensor<mint> t {std::begin(v), std::end(v), {2, 2}};
	mngr.set(t);

	return LLU::ErrorCode::NoError;
}

LIBRARY_LINK_FUNCTION(FlattenThroughVector) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);
	auto t = mngr.getTensor<mint>(0);
	auto v = t.asVector();

	Tensor<mint> t2 {v};
	mngr.set(t2);

	return LLU::ErrorCode::NoError;
}

LIBRARY_LINK_FUNCTION(CopyThroughNumericArray) {
	LLU::MArgumentManager mngr(libData, Argc, Args, Res);
	auto t = mngr.getTensor<mint>(0);
	LLU::NumericArray<mint> na {std::begin(t), std::end(t), t.dimensions()};

	Tensor<mint> t2 {na, na.dimensions()};
	mngr.set(t2);

	return LLU::ErrorCode::NoError;
}

auto getLargest(const std::vector<LLU::TensorView>& tens) {
	return std::max_element(std::cbegin(tens), std::cend(tens),
							[](const LLU::TensorView& ten1, const LLU::TensorView& ten2) { return ten1.getFlattenedLength() < ten2.getFlattenedLength(); });
}

LLU_LIBRARY_FUNCTION(GetLargest) {
	auto tenAuto = mngr.getTensor<mint>(0);
	auto tenConstant = mngr.getGenericTensor<LLU::Passing::Constant>(1);
	auto tenManual = mngr.getTensor<double, LLU::Passing::Manual>(2);
	std::vector<LLU::TensorView> tens {tenAuto, tenConstant, tenManual};
	auto largest = getLargest(tens);
	mngr.set(static_cast<mint>(std::distance(std::cbegin(tens), largest)));

	// perform some random assignments and copies to see if they compile
	std::swap(tens[0], tens[1]);
	LLU::TensorView iv = std::move(tens[2]);
	tens[2] = iv;
}

// The following will crash, even though the same test for Image and NumericArray returns consistent results
LLU_LIBRARY_FUNCTION(EmptyView) {
	LLU::TensorView v;
	// NOLINTNEXTLINE
	Tensor<mint> t {v.getRank(), v.getFlattenedLength(), reinterpret_cast<mint>(v.rawData()), static_cast<mint>(v.type())};
	mngr.set(t);
}

LLU_LIBRARY_FUNCTION(Reverse) {
	auto naConstant = mngr.getGenericTensor<LLU::Passing::Constant>(0);
	LLU::asTypedTensor(naConstant, [&mngr](auto&& typedNA) {
		using T = typename std::remove_reference_t<decltype(typedNA)>::value_type;
		mngr.set(Tensor<T>(std::crbegin(typedNA), std::crend(typedNA), LLU::MArrayDimensions{typedNA.getDimensions(), typedNA.getRank()}));
	});
}