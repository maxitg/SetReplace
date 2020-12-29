/**
 * @file	Get.cpp
 * @date	Nov 28, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Implementation file with classes related to reading data from WSTP.
 */
#ifndef _WIN32

#include "LLU/WSTP/Get.h"

#include "wstp.h"

namespace LLU::WS {

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

} /* namespace LLU::WS */

#endif
