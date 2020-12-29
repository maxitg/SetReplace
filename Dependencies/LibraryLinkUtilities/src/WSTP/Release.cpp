/**
 * @file	Release.cpp
 * @date	Nov 28, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Implementation file with classes responsible for releasing memory allocated by WSTP when receiving data.
 */
#ifndef _WIN32

#include "LLU/WSTP/Release.h"

namespace LLU::WS {
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

}	 // namespace LLU::WS

#endif
