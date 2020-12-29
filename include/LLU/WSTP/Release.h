/**
 * @file	Release.h
 * @date	Nov 28, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Header file with classes responsible for releasing memory allocated by WSTP when receiving data.
 */
#ifndef LLU_WSTP_RELEASE_H_
#define LLU_WSTP_RELEASE_H_

#include <functional>

#include "wstp.h"

#include "LLU/Utilities.hpp"

namespace LLU::WS {

	template<typename T>
	struct ReleaseList {
		using Func = std::function<void(WSLINK, T*, int)>;

		ReleaseList() = default;
		ReleaseList(WSLINK m, int l) : m(m), length(l) {}

		void operator()(T* data) {
			Release(m, data, length);
		}

		int getLength() const {
			return length;
		}

	private:
		static Func Release;

		WSLINK m = nullptr;
		int length = 0;
	};

	template<typename T>
	struct ReleaseArray {
		using Func = std::function<void(WSLINK, T*, int*, char**, int)>;

		ReleaseArray() = default;
		ReleaseArray(WSLINK m, int* d, char** h, int r) : m(m), dims(d), heads(h), rank(r) {}

		void operator()(T* data) {
			Release(m, data, dims, heads, rank);
		}

		int* getDims() const {
			return dims;
		}

		char** getHeads() const {
			return heads;
		}

		int getRank() const {
			return rank;
		}

	private:
		static Func Release;

		WSLINK m = nullptr;
		int* dims = nullptr;
		char** heads = nullptr;
		int rank = 0;
	};

	template<typename T>
	typename ReleaseArray<T>::Func ReleaseArray<T>::Release = [](WSLINK /*link*/, T* /*array*/, int* /*dims*/, char** /*heads*/, int /*rank*/) {
		static_assert(dependent_false_v<T>, "Trying to use WS::ReleaseArray<T>::Release for unsupported type T");
	};

	template<typename T>
	typename ReleaseList<T>::Func ReleaseList<T>::Release = [](WSLINK /*link*/, T* /*list*/, int /*length*/) {
		static_assert(dependent_false_v<T>, "Trying to use WS::ReleaseList<T>::Release for unsupported type T");
	};

/// @cond
#ifndef _WIN32

#define WS_RELEASE_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(T) \
	template<>                                                  \
	ReleaseArray<T>::Func ReleaseArray<T>::Release;             \
	template<>                                                  \
	ReleaseList<T>::Func ReleaseList<T>::Release;

	WS_RELEASE_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(unsigned char)
	WS_RELEASE_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(short)
	WS_RELEASE_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(int)
	WS_RELEASE_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(wsint64)
	WS_RELEASE_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(float)
	WS_RELEASE_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(double)
#else

	template<>
	ReleaseArray<unsigned char>::Func ReleaseArray<unsigned char>::Release = WSReleaseInteger8Array;

	template<>
	ReleaseList<unsigned char>::Func ReleaseList<unsigned char>::Release = WSReleaseInteger8List;

	template<>
	ReleaseArray<short>::Func ReleaseArray<short>::Release = WSReleaseInteger16Array;

	template<>
	ReleaseList<short>::Func ReleaseList<short>::Release = WSReleaseInteger16List;

	template<>
	ReleaseArray<int>::Func ReleaseArray<int>::Release = WSReleaseInteger32Array;

	template<>
	ReleaseList<int>::Func ReleaseList<int>::Release = WSReleaseInteger32List;

	template<>
	ReleaseArray<wsint64>::Func ReleaseArray<wsint64>::Release = WSReleaseInteger64Array;

	template<>
	ReleaseList<wsint64>::Func ReleaseList<wsint64>::Release = WSReleaseInteger64List;

	template<>
	ReleaseArray<float>::Func ReleaseArray<float>::Release = WSReleaseReal32Array;

	template<>
	ReleaseList<float>::Func ReleaseList<float>::Release = WSReleaseReal32List;

	template<>
	ReleaseArray<double>::Func ReleaseArray<double>::Release = WSReleaseReal64Array;

	template<>
	ReleaseList<double>::Func ReleaseList<double>::Release = WSReleaseReal64List;
#endif
/// @endcond

} /* namespace LLU::WS */

#endif /* LLU_WSTP_RELEASE_H_ */
