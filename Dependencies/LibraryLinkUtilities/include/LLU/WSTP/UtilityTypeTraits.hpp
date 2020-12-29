/**
 * @file	UtilityTypeTraits.hpp
 * @date	Feb 7, 2018
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Type traits used by WSStream to identify types supported by WSTP
 */
#ifndef LLU_WSTP_UTILITYTYPETRAITS_HPP_
#define LLU_WSTP_UTILITYTYPETRAITS_HPP_

#include <type_traits>

#include "wstp.h"

#include "LLU/Utilities.hpp"

namespace LLU::WS {

	/**
	 * @brief	Utility trait that determines whether type T is a suitable data type for functions like WSPut*Array, WSGet*List, WSPutScalar, etc.
	 * @tparam	T - any type
	 */
	template<typename T>
	inline constexpr bool supportedInWSArithmeticQ = false;

	/// @cond
	template<>
	inline constexpr bool supportedInWSArithmeticQ<unsigned char> = true;
	template<>
	inline constexpr bool supportedInWSArithmeticQ<short> = true;
	template<>
	inline constexpr bool supportedInWSArithmeticQ<int> = true;
	template<>
	inline constexpr bool supportedInWSArithmeticQ<wsint64> = true;
	template<>
	inline constexpr bool supportedInWSArithmeticQ<float> = true;
	template<>
	inline constexpr bool supportedInWSArithmeticQ<double> = true;
	/// @endcond

	/// Convenient alias for supportedInWSArithmeticQ<T> that strips T from cv-qualifiers and reference.
	template<typename T>
	inline constexpr bool ScalarSupportedTypeQ = supportedInWSArithmeticQ<remove_cv_ref<T>>;

	/**
	 * @brief	Utility trait that determines whether type T is a suitable character type for WSPut*String and WSGet*String
	 * @tparam	T - any type
	 */
	template<typename T>
	inline constexpr bool supportedInWSStringQ = false;

	/// @cond
	template<>
	inline constexpr bool supportedInWSStringQ<char> = true;
	template<>
	inline constexpr bool supportedInWSStringQ<unsigned char> = true;
	template<>
	inline constexpr bool supportedInWSStringQ<unsigned short> = true;
	template<>
	inline constexpr bool supportedInWSStringQ<unsigned int> = true;
	/// @endcond

	/// Convenient alias for supportedInWSStringQ<T> that strips T from cv-qualifiers and reference.
	template<typename T>
	inline constexpr bool StringTypeQ = supportedInWSStringQ<remove_cv_ref<T>>;

}  // namespace LLU::WS

#endif /* LLU_WSTP_UTILITYTYPETRAITS_HPP_ */
