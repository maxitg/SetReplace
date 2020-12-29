#include <list>
#include <memory>
#include <numeric>
#include <type_traits>

#include <LLU/Containers/Views/NumericArray.hpp>
#include <LLU/ErrorLog/Logger.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/MArgumentManager.h>

namespace NA = LLU::NA;
namespace ErrorCode = LLU::ErrorCode;

using LLU::MArgumentManager;
using LLU::NumericArray;
using LLU::NumericArrayView;

static std::unique_ptr<LLU::GenericNumericArray> shared_numeric;

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	LLU::ErrorManager::registerPacletErrors({{"InvalidConversionMethod", "NumericArray conversion method `method` is invalid."}});
	return 0;
}

LIBRARY_LINK_FUNCTION(CreateEmptyVector) {
	MArgumentManager mngr(libData, Argc, Args, Res);

	NumericArray<std::uint16_t> out(0, {0});

	mngr.setNumericArray(out);
	return ErrorCode::NoError;
}

LIBRARY_LINK_FUNCTION(CreateEmptyMatrix) {
	MArgumentManager mngr(libData, Argc, Args, Res);

	NumericArray<double> out(0, {3, 5, 0});

	mngr.setNumericArray(out);
	return ErrorCode::NoError;
}

struct MoveTester {
	LLU::DataList<LLU::GenericNumericArray>& result;

	template<typename T>
	void operator()(NumericArray<T> na) {
		auto na2 {std::move(na)};	 // test move constructor
		NumericArray<T> na3;
		na3 = std::move(na2);	 // test move assignment
		result.push_back(std::move(na3));
	}
};

LLU_LIBRARY_FUNCTION(echoNumericArrays) {
	LLU::DataList<LLU::GenericNumericArray> result;

	MoveTester mt {result};

	mngr.operateOnNumericArray(0, mt);
	mngr.operateOnNumericArray<LLU::Passing::Manual>(1, mt);
	mngr.operateOnNumericArray<LLU::Passing::Shared>(2, mt);

	mngr.set(result);
}

/*
 * Numeric array library functions
 */
LLU_LIBRARY_FUNCTION(getNumericArrayLength) {
	mngr.operateOnNumericArray(0, [&mngr](auto&& rarray) { mngr.setInteger(rarray.size()); });
}

LLU_LIBRARY_FUNCTION(getNumericArrayRank) {
	mngr.operateOnNumericArray(0, [&mngr](auto&& rarray) { mngr.setInteger(rarray.rank()); });
}

// create new numeric array
LLU_LIBRARY_FUNCTION(newNumericArray) {
	NumericArray<float> ra(0., {3, 3});
	mngr.setNumericArray(ra);
}

struct CopyTester {
	LLU::DataList<LLU::GenericNumericArray>& result;

	template<typename T>
	void operator()(NumericArray<T> na) {
		NumericArray<T> na2 {na.clone()};
		NumericArray<T> na3;
		na3 = na2.clone();
		// NOLINTNEXTLINE(cppcoreguidelines-slicing): deliberate slicing
		result.push_back(na3.clone());
	}
};

// clone NumericArray
LLU_LIBRARY_FUNCTION(cloneNumericArrays) {
	LLU::DataList<LLU::GenericNumericArray> result;

	CopyTester mt {result};

	mngr.operateOnNumericArray(0, mt);
	mngr.operateOnNumericArray<LLU::Passing::Manual>(1, mt);
	mngr.operateOnNumericArray<LLU::Passing::Shared>(2, mt);

	mngr.set(result);
}

LLU_LIBRARY_FUNCTION(changeSharedNumericArray) {
	auto oldShareCount = shared_numeric ? shared_numeric->shareCount() : 0;
	shared_numeric = std::make_unique<LLU::GenericNumericArray>(mngr.getGenericNumericArray<LLU::Passing::Shared>(0));
	mngr.set(10 * oldShareCount + shared_numeric->shareCount());
}

LIBRARY_LINK_FUNCTION(getSharedNumericArray) {
	auto err = ErrorCode::NoError;
	try {
		MArgumentManager mngr(Argc, Args, Res);
		if (shared_numeric) {
			mngr.set(*shared_numeric);
		} else {
			return ErrorCode::FunctionError;
		}
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

struct ZeroReal64 {
	template<typename T>
	void operator()(NumericArray<T>&& /*unused*/, MArgumentManager& /*unused*/) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}

	void operator()(NumericArray<double>&& ra, MArgumentManager& mngr) {
		std::fill(ra.begin(), ra.end(), 0.0);
		mngr.setNumericArray(ra);
	}
};

// reset NumericArray
LLU_LIBRARY_FUNCTION(numericZeroData) {
	mngr.operateOnNumericArray<LLU::Passing::Automatic, ZeroReal64>(0, mngr);
}

struct AccumulateIntegers {
	template<typename T>
	std::enable_if_t<!std::is_integral<T>::value> operator()(const NumericArray<T>& /*unused*/, MArgumentManager& /*unused*/) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}

	template<typename T>
	std::enable_if_t<std::is_integral<T>::value> operator()(const NumericArray<T>& ra, MArgumentManager& mngr) {
		auto result = std::accumulate(ra.begin(), ra.end(), static_cast<T>(0));
		mngr.setInteger(result);
	}
};

// sum elements of a NumericArray but only if it is of integer type
LLU_LIBRARY_FUNCTION(accumulateIntegers) {
	mngr.operateOnNumericArray<LLU::Passing::Constant, AccumulateIntegers>(0, mngr);
}

// check if conversion methods are mapped correctly
LLU_LIBRARY_FUNCTION(convertMethodName) {
	auto method = mngr.getInteger<NA::ConversionMethod>(0);
	std::string methodStr;
	switch (method) {
		case NA::ConversionMethod::Check: methodStr = "Check"; break;
		case NA::ConversionMethod::ClipCheck: methodStr = "ClipCheck"; break;
		case NA::ConversionMethod::Coerce: methodStr = "Coerce"; break;
		case NA::ConversionMethod::ClipCoerce: methodStr = "ClipCoerce"; break;
		case NA::ConversionMethod::Round: methodStr = "Round"; break;
		case NA::ConversionMethod::ClipRound: methodStr = "ClipRound"; break;
		case NA::ConversionMethod::Scale: methodStr = "Scale"; break;
		case NA::ConversionMethod::ClipScale: methodStr = "ClipScale"; break;
		default: LLU::ErrorManager::throwException("InvalidConversionMethod", static_cast<int>(method));
	}
	mngr.setString(std::move(methodStr));
}

// convert NumericArray
LLU_LIBRARY_FUNCTION(convert) {
	mngr.operateOnNumericArray(0, [&mngr](auto&& numArr) {
		NumericArray<std::uint16_t> converted {numArr, mngr.getInteger<NA::ConversionMethod>(1), mngr.getReal(2)};
		mngr.setNumericArray(converted);
	});
}

// convert generic NumericArray
LLU_LIBRARY_FUNCTION(convertGeneric) {
	auto numArr = mngr.getGenericNumericArray(0);
	NumericArray<std::uint16_t> converted {numArr, mngr.getInteger<NA::ConversionMethod>(1), mngr.getReal(2)};
	mngr.set(converted);
}

LLU_LIBRARY_FUNCTION(TestDimensions) {
	auto dims = mngr.getTensor<mint>(0);
	NumericArray<float> na(0.0, LLU::MArrayDimensions {dims.asVector()});
	mngr.setNumericArray(na);
}

LLU_LIBRARY_FUNCTION(TestDimensions2) {
	LLU::DataList<LLU::GenericNumericArray> naList;

	std::vector<std::vector<mint>> dimsList {{0}, {3}, {3, 0}, {3, 2}, {3, 2, 0}, {3, 2, 4}};

	for (auto& dims : dimsList) {
		NumericArray<float> na(0.0F, LLU::MArrayDimensions {dims});
		naList.push_back(std::move(na));
	}
	mngr.setDataList(naList);
}

LLU_LIBRARY_FUNCTION(FlattenThroughList) {
	LLU_DEBUG("NumericArray type is ", NA::typeToString(mngr.getNumericArrayType(0)));
	auto na = mngr.getNumericArray<std::int32_t>(0);
	std::list<std::int32_t> l {na.begin(), na.end()};
	NumericArray<std::int32_t> na2 {l};
	mngr.set(na2);
}

LLU_LIBRARY_FUNCTION(CopyThroughTensor) {
	LLU_DEBUG("NumericArray type is ", NA::typeToString(mngr.getNumericArrayType(0)));
	auto na = mngr.getNumericArray<double>(0);
	LLU::Tensor<double> t {na, na.dimensions()};
	NumericArray<double> na2 {t, t.dimensions()};
	mngr.set(na2);
}

auto getLargest(const std::vector<NumericArrayView>& nas) {
	return std::max_element(std::cbegin(nas), std::cend(nas),
							[](const NumericArrayView& na1, const NumericArrayView& na2) { return na1.getFlattenedLength() < na2.getFlattenedLength(); });
}

LLU_LIBRARY_FUNCTION(GetLargest) {
	auto naAuto = mngr.getNumericArray<std::uint16_t>(0);
	auto naConstant = mngr.getGenericNumericArray<LLU::Passing::Constant>(1);
	auto naManual = mngr.getNumericArray<double, LLU::Passing::Manual>(2);
	std::vector<NumericArrayView> nas {NumericArrayView {naAuto}, NumericArrayView {naConstant}, NumericArrayView {naManual}};
	auto largest = getLargest(nas);
	mngr.set(static_cast<mint>(std::distance(std::cbegin(nas), largest)));

	// perform some random assignments and copies to see it they compile
	std::swap(nas[0], nas[1]);
	NumericArrayView iv = std::move(nas[2]);
	nas[2] = iv;
}

LLU_LIBRARY_FUNCTION(EmptyView) {
	NumericArrayView v;
	// NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): we want to send the address of the data as mint
	LLU::Tensor<mint> t {v.getRank(), v.getFlattenedLength(), reinterpret_cast<mint>(v.rawData()), static_cast<mint>(v.type())};
	mngr.set(t);
}

mint largestDimension(const NumericArrayView& na) {
	return *std::max_element(na.getDimensions(), std::next(na.getDimensions(), na.getRank()));
}

LLU_LIBRARY_FUNCTION(SumLargestDimensions) {
	auto naAuto = mngr.getNumericArray<std::uint16_t>(0);
	auto naConstant = mngr.getGenericNumericArray<LLU::Passing::Constant>(1);
	mngr.set(largestDimension(naAuto) + largestDimension(naConstant));
}

LLU_LIBRARY_FUNCTION(Reverse) {
	auto naConstant = mngr.getGenericNumericArray<LLU::Passing::Constant>(0);
	LLU::asTypedNumericArray(naConstant, [&mngr](auto&& typedNA) {
		using T = typename std::remove_reference_t<decltype(typedNA)>::value_type;
		mngr.set(NumericArray<T>(std::crbegin(typedNA), std::crend(typedNA), LLU::MArrayDimensions {typedNA.getDimensions(), typedNA.getRank()}));
	});
}