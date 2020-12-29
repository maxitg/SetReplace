/**
 * @file	Put.cpp
 * @date	Nov 28, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Implementation file with classes related to sending data through WSTP.
 */

#ifndef _WIN32

#include "LLU/WSTP/Put.h"

#include "wstp.h"

#include "LLU/Utilities.hpp"

namespace LLU::WS {

    /* ***************************************************************** */
    /* ********* Template specializations for  unsigned char  ********** */
    /* ***************************************************************** */

    /* PutArray */

    template<>
    PutArray<unsigned char>::Func PutArray<unsigned char>::ArrayF = WSPutInteger8Array;

    template<>
    const std::string PutArray<unsigned char>::ArrayFName = "WSPutInteger8Array";

    /* PutList */

    template<>
    PutList<unsigned char>::Func PutList<unsigned char>::ListF = WSPutInteger8List;

    template<>
    const std::string PutList<unsigned char>::ListFName = "WSPutInteger8List";

    /* PutScalar */

    template<>
    PutScalar<unsigned char>::Func PutScalar<unsigned char>::ScalarF = WSPutInteger8;

    template<>
    const std::string PutScalar<unsigned char>::ScalarFName = "WSPutInteger8";


    /* ***************************************************************** */
    /* ******* Template specializations for  (unsigned) short  ********* */
    /* ***************************************************************** */

    /* PutArray */

    template<>
    PutArray<short>::Func PutArray<short>::ArrayF = WSPutInteger16Array;

    template<>
    const std::string PutArray<short>::ArrayFName = "WSPutInteger16Array";

    /* PutList */

    template<>
    PutList<short>::Func PutList<short>::ListF = WSPutInteger16List;

    template<>
    const std::string PutList<short>::ListFName = "WSPutInteger16List";

    /* PutScalar */

    template<>
    PutScalar<short>::Func PutScalar<short>::ScalarF = WSPutInteger16;

    template<>
    const std::string PutScalar<short>::ScalarFName = "WSPutInteger16";


    /* ***************************************************************** */
    /* ******** Template specializations for  (unsigned) int  ********** */
    /* ***************************************************************** */

    /* PutArray */

    template<>
    PutArray<int>::Func PutArray<int>::ArrayF = WSPutInteger32Array;

    template<>
    const std::string PutArray<int>::ArrayFName = "WSPutInteger32Array";

    /* PutList */

    template<>
    PutList<int>::Func PutList<int>::ListF = WSPutInteger32List;

    template<>
    const std::string PutList<int>::ListFName = "WSPutInteger32List";

    /* PutScalar */

    template<>
    PutScalar<int>::Func PutScalar<int>::ScalarF = WSPutInteger32;

    template<>
    const std::string PutScalar<int>::ScalarFName = "WSPutInteger32";


    /* ***************************************************************** */
    /* *********** Template specializations for  wsint64  ************** */
    /* ***************************************************************** */

    /* PutArray */

    template<>
    PutArray<wsint64>::Func PutArray<wsint64>::ArrayF = WSPutInteger64Array;

    template<>
    const std::string PutArray<wsint64>::ArrayFName = "WSPutInteger64Array";

    /* PutList */

    template<>
    PutList<wsint64>::Func PutList<wsint64>::ListF = WSPutInteger64List;

    template<>
    const std::string PutList<wsint64>::ListFName = "WSPutInteger64List";

    /* PutScalar */

    template<>
    PutScalar<wsint64>::Func PutScalar<wsint64>::ScalarF = WSPutInteger64;

    template<>
    const std::string PutScalar<wsint64>::ScalarFName = "WSPutInteger64";


    /* ***************************************************************** */
    /* ************ Template specializations for  float  *************** */
    /* ***************************************************************** */

    /* PutArray */

    template<>
    PutArray<float>::Func PutArray<float>::ArrayF = WSPutReal32Array;

    template<>
    const std::string PutArray<float>::ArrayFName = "WSPutReal32Array";

    /* PutList */

    template<>
    PutList<float>::Func PutList<float>::ListF = WSPutReal32List;

    template<>
    const std::string PutList<float>::ListFName = "WSPutReal32List";

    /* PutScalar */

    template<>
    PutScalar<float>::Func PutScalar<float>::ScalarF = WSPutReal32;

    template<>
    const std::string PutScalar<float>::ScalarFName = "WSPutReal32";


    /* ***************************************************************** */
    /* *********** Template specializations for  double  *************** */
    /* ***************************************************************** */

    /* PutArray */

    template<>
    PutArray<double>::Func PutArray<double>::ArrayF = WSPutReal64Array;

    template<>
    const std::string PutArray<double>::ArrayFName = "WSPutReal64Array";

    /* PutList */

    template<>
    PutList<double>::Func PutList<double>::ListF = WSPutReal64List;

    template<>
    const std::string PutList<double>::ListFName = "WSPutReal64List";

    /* PutScalar */

    template<>
    PutScalar<double>::Func PutScalar<double>::ScalarF = WSPutReal64;

    template<>
    const std::string PutScalar<double>::ScalarFName = "WSPutReal64";


} /* namespace LLU::WS */

#endif
