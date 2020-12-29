/**
 * @file	Get.h
 * @date	Nov 28, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Header file with classes related to reading data from WSTP.
 */
#ifndef LLU_WSTP_GET_H_
#define LLU_WSTP_GET_H_

#include <functional>
#include <memory>
#include <string>

#include "wstp.h"

#include "LLU/ErrorLog/Errors.h"
#include "LLU/Utilities.hpp"
#include "LLU/WSTP/Release.h"
#include "LLU/WSTP/Utilities.h"

namespace LLU::WS {

	/// ListData with of type \p T is a unique_ptr to an array of Ts with custom destructor.
	/// It allows you to take ownership of raw list data from WSTP without making extra copies.
	/// The destructor object also carries information about the list's length.
	template<typename T>
	using ListData = std::unique_ptr<T[], ReleaseList<T>>;

	/// ArrayData with of type \p T is a unique_ptr to an array of Ts with custom destructor.
	/// It allows you to take ownership of raw array data from WSTP without making extra copies.
	/// The destructor object also carries information about the array's dimensions and heads.
	template<typename T>
	using ArrayData = std::unique_ptr<T[], ReleaseArray<T>>;

	template<typename T>
	struct GetArray {
		using Func = std::function<int(WSLINK, T**, int**, char***, int*)>;

		static ArrayData<T> get(WSLINK m) {
			T* rawResult {};
			int* dims {};
			char** heads {};
			int rank {};
			Detail::checkError(m, ArrayF(m, &rawResult, &dims, &heads, &rank), ErrorName::WSGetArrayError, ArrayFName);
			return {rawResult, ReleaseArray<T> {m, dims, heads, rank}};
		}

	private:
		static const std::string ArrayFName;
		static Func ArrayF;
	};

	template<typename T>
	struct GetList {
		using Func = std::function<int(WSLINK, T**, int*)>;

		static ListData<T> get(WSLINK m) {
			T* rawResult {};
			int len {};
			Detail::checkError(m, ListF(m, &rawResult, &len), ErrorName::WSGetListError, ListFName);
			return {rawResult, ReleaseList<T> {m, len}};
		}

	private:
		static const std::string ListFName;
		static Func ListF;
	};

	template<typename T>
	struct GetScalar {
		using Func = std::function<int(WSLINK, T*)>;

		static T get(WSLINK m) {
			T rawResult;
			Detail::checkError(m, ScalarF(m, &rawResult), ErrorName::WSGetScalarError, ScalarFName);
			return rawResult;
		}

	private:
		static const std::string ScalarFName;
		static Func ScalarF;
	};

	template<typename T>
	typename GetArray<T>::Func GetArray<T>::ArrayF = [](WSLINK /*link*/, T** /*rawResult*/, int** /*dims*/, char*** /*heads*/, int* /*rank*/) {
		static_assert(dependent_false_v<T>, "Trying to use WS::GetArray<T> for unsupported type T");
		return 0;
	};

	template<typename T>
	typename GetList<T>::Func GetList<T>::ListF = [](WSLINK /*link*/) {
		static_assert(dependent_false_v<T>, "Trying to use WS::GetList<T> for unsupported type T");
		return 0;
	};

	template<typename T>
	typename GetScalar<T>::Func GetScalar<T>::ScalarF = [](WSLINK /*link*/, T* /*result*/) {
		static_assert(dependent_false_v<T>, "Trying to use WS::GetScalar<T> for unsupported type T");
		return 0;
	};

/// @cond
#ifndef _WIN32

#define WS_GET_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(T) \
	template<>                                              \
	GetArray<T>::Func GetArray<T>::ArrayF;                  \
	template<>                                              \
	const std::string GetArray<T>::ArrayFName;              \
	template<>                                              \
	GetList<T>::Func GetList<T>::ListF;                     \
	template<>                                              \
	const std::string GetList<T>::ListFName;                \
	template<>                                              \
	GetScalar<T>::Func GetScalar<T>::ScalarF;               \
	template<>                                              \
	const std::string GetScalar<T>::ScalarFName;

	WS_GET_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(unsigned char)
	WS_GET_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(short)
	WS_GET_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(int)
	WS_GET_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(wsint64)
	WS_GET_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(float)
	WS_GET_DECLARE_SPECIALIZATIONS_OF_STATIC_MEMBERS(double)

#else

	/* ***************************************************************** */
	/* ********* Template specializations for  unsigned char  ********** */
	/* ***************************************************************** */

	/* GetArray */

	template<>
	GetArray<unsigned char>::Func GetArray<unsigned char>::ArrayF = WSGetInteger8Array;

	template<>
	const std::string GetArray<unsigned char>::ArrayFName = "WSGetInteger8Array";

	/* GetList */

	template<>
	GetList<unsigned char>::Func GetList<unsigned char>::ListF = WSGetInteger8List;

	template<>
	const std::string GetList<unsigned char>::ListFName = "WSGetInteger8List";

	/* GetScalar */

	template<>
	GetScalar<unsigned char>::Func GetScalar<unsigned char>::ScalarF = WSGetInteger8;

	template<>
	const std::string GetScalar<unsigned char>::ScalarFName = "WSGetInteger8";

	/* ***************************************************************** */
	/* ******* Template specializations for  (unsigned) short  ********* */
	/* ***************************************************************** */

	/* GetArray */

	template<>
	GetArray<short>::Func GetArray<short>::ArrayF = WSGetInteger16Array;

	template<>
	const std::string GetArray<short>::ArrayFName = "WSGetInteger16Array";

	/* GetList */

	template<>
	GetList<short>::Func GetList<short>::ListF = WSGetInteger16List;

	template<>
	const std::string GetList<short>::ListFName = "WSGetInteger16List";

	/* GetScalar */

	template<>
	GetScalar<short>::Func GetScalar<short>::ScalarF = WSGetInteger16;

	template<>
	const std::string GetScalar<short>::ScalarFName = "WSGetInteger16";

	/* ***************************************************************** */
	/* ******** Template specializations for  (unsigned) int  ********** */
	/* ***************************************************************** */

	/* GetArray */

	template<>
	GetArray<int>::Func GetArray<int>::ArrayF = WSGetInteger32Array;

	template<>
	const std::string GetArray<int>::ArrayFName = "WSGetInteger32Array";

	/* GetList */

	template<>
	GetList<int>::Func GetList<int>::ListF = WSGetInteger32List;

	template<>
	const std::string GetList<int>::ListFName = "WSGetInteger32List";

	/* GetScalar */

	template<>
	GetScalar<int>::Func GetScalar<int>::ScalarF = WSGetInteger32;

	template<>
	const std::string GetScalar<int>::ScalarFName = "WSGetInteger32";

	/* ***************************************************************** */
	/* *********** Template specializations for  wsint64  ************** */
	/* ***************************************************************** */

	/* GetArray */

	template<>
	GetArray<wsint64>::Func GetArray<wsint64>::ArrayF = WSGetInteger64Array;

	template<>
	const std::string GetArray<wsint64>::ArrayFName = "WSGetInteger64Array";

	/* GetList */

	template<>
	GetList<wsint64>::Func GetList<wsint64>::ListF = WSGetInteger64List;

	template<>
	const std::string GetList<wsint64>::ListFName = "WSGetInteger64List";

	/* GetScalar */

	template<>
	GetScalar<wsint64>::Func GetScalar<wsint64>::ScalarF = WSGetInteger64;

	template<>
	const std::string GetScalar<wsint64>::ScalarFName = "WSGetInteger64";

	/* ***************************************************************** */
	/* ************ Template specializations for  float  *************** */
	/* ***************************************************************** */

	/* GetArray */

	template<>
	GetArray<float>::Func GetArray<float>::ArrayF = WSGetReal32Array;

	template<>
	const std::string GetArray<float>::ArrayFName = "WSGetReal32Array";

	/* GetList */

	template<>
	GetList<float>::Func GetList<float>::ListF = WSGetReal32List;

	template<>
	const std::string GetList<float>::ListFName = "WSGetReal32List";

	/* GetScalar */

	template<>
	GetScalar<float>::Func GetScalar<float>::ScalarF = WSGetReal32;

	template<>
	const std::string GetScalar<float>::ScalarFName = "WSGetReal32";

	/* ***************************************************************** */
	/* *********** Template specializations for  double  *************** */
	/* ***************************************************************** */

	/* GetArray */

	template<>
	GetArray<double>::Func GetArray<double>::ArrayF = WSGetReal64Array;

	template<>
	const std::string GetArray<double>::ArrayFName = "WSGetReal64Array";

	/* GetList */

	template<>
	GetList<double>::Func GetList<double>::ListF = WSGetReal64List;

	template<>
	const std::string GetList<double>::ListFName = "WSGetReal64List";

	/* GetScalar */

	template<>
	GetScalar<double>::Func GetScalar<double>::ScalarF = WSGetReal64;

	template<>
	const std::string GetScalar<double>::ScalarFName = "WSGetReal64";
#endif
/// @endcond
} /* namespace LLU::WS */

#endif /* LLU_WSTP_GET_H_ */
