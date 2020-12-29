#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/MArgumentManager.h>

/* Gets the I0 th Real number from the rank 1 tensor T0 */
LLU_LIBRARY_FUNCTION(getNthRealFromTR1) {
		auto t = mngr.getTensor<double>(0);
		auto i = mngr.getInteger<mint>(1) - 1;

		mngr.setReal(t.at(i));	  // we use at() here to verify if the index i is not out-of-bounds
}

/* Gets the (m,n) Real number from the rank 2 tensor T0 */
LLU_LIBRARY_FUNCTION(getNthRealFromTR2) {
		auto t = mngr.getTensor<double>(0);
		auto i = mngr.getInteger<mint>(1) - 1;
		auto j = mngr.getInteger<mint>(2) - 1;

		mngr.setReal(t[{i, j}]);
}

/* Gets the (m,n) Integer number from the rank 2 tensor T0 */
LLU_LIBRARY_FUNCTION(getNthIntegerFromTR2) {
		auto t = mngr.getTensor<mint>(0);
		auto i = mngr.getInteger<mint>(1) - 1;
		auto j = mngr.getInteger<mint>(2) - 1;

		mngr.setInteger(t[{i, j}]);
}

/**
 * Constructs a new rank 1 tensor of length I0, and sets the
 * ith element of the vector to 2*i
 **/
LLU_LIBRARY_FUNCTION(setNthIntegerT) {
		auto len = mngr.getInteger<mint>(0);

		LLU::Tensor<mint> t(0, {len});
		mint val = 2;
		std::for_each(t.begin(), t.end(), [&val](mint& elem) {
			elem = val;
			val += 2;
		});
		mngr.setTensor(t);
}

/* Sets the element in the I0,I1 position in T0 to its value in T1, returning T0 */
LIBRARY_LINK_FUNCTION(setI0I1T) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto T0 = mngr.getGenericTensor(0);
	auto T1 = mngr.getGenericTensor(1);
	auto [I1, I2] = mngr.getTuple<mint, mint>(2);
	std::array<mint, 2> pos {I1, I2};
	if (auto err = LLU::LibraryData::API()->MTensor_setMTensor(T0.getContainer(), T1.getContainer(), pos.data(), 2); err != LIBRARY_NO_ERROR) {
		return err;
	}
	mngr.set(T0);
	return LLU::ErrorCode::NoError;
}

/* Gets the subpart of the input tensor starting at the I0,I1 th position */
LIBRARY_LINK_FUNCTION(getSubpartT) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto T0 = mngr.getGenericTensor(0);
	auto [I1, I2] = mngr.getTuple<mint, mint>(1);
	std::array<mint, 2> pos {I1, I2};
	MTensor T1 {};
	if (auto err = LLU::LibraryData::API()->MTensor_getMTensor(T0.getContainer(), pos.data(), 2, &T1); err != LIBRARY_NO_ERROR) {
		return err;
	}
	mngr.setMTensor(T1);
	return LLU::ErrorCode::NoError;
}
