/**
 * @file	Utilities.hpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	8/07/2017
 *
 * @brief	Short but generally useful functions
 *
 */
#ifndef LLU_UTILITIES_HPP
#define LLU_UTILITIES_HPP

#include <complex>
#include <cstdint>
#include <type_traits>
#include <utility>
#include <variant>

#include "LLU/LibraryData.h"

namespace LLU {

	/**
	 * @brief 	Utility type that strips any given type from reference and cv qualifiers
	 * @tparam	T - any type
	 */
	template<typename T>
	using remove_cv_ref = std::remove_cv_t<std::remove_reference_t<T>>;

	/**
	 * @brief 	Utility type that is valid only if B is not A and not a subclass of A
	 * @tparam	A - any type
	 * @tparam	B - any type, will be stripped of reference and cv-qualifiers before comparing with A
	 */
	template<typename A, typename B>
	using disable_if_same_or_derived = typename std::enable_if_t<!std::is_same<A, B>::value && !std::is_base_of<A, remove_cv_ref<B>>::value>;

	/**
	 * @brief 	Utility type that is valid only if B is A or a subclass of A
	 * @tparam	A - any type
	 * @tparam	B - any type, will be stripped of reference and cv-qualifiers before comparing with A
	 */
	template<typename A, typename B>
	using enable_if_same_or_derived = typename std::enable_if_t<std::is_same<A, B>::value || std::is_base_of<A, remove_cv_ref<B>>::value>;

	/**
	 * @brief 	Utility type that checks if given type can be treated as input iterator
	 * @tparam	Iterator - iterator type
	 */
	template<typename Iterator>
	using enable_if_input_iterator = enable_if_same_or_derived<std::input_iterator_tag, typename std::iterator_traits<Iterator>::iterator_category>;

	/**
	 * @brief 	Utility type that checks if given container type has elements that are integers (and therefore can be used as Tensor or NumericArray dimensions)
	 * @tparam	Container - container type
	 */
	template<typename Container>
	using enable_if_integral_elements = typename std::enable_if_t<std::is_integral<typename std::remove_reference_t<Container>::value_type>::value>;

	template<typename Container, typename = std::void_t<>>
	struct has_value_type : std::false_type {};

	template<typename Container>
	struct has_value_type<Container, std::void_t<typename Container::value_type>> : std::true_type {};

	template<typename Container, typename T>
	struct has_matching_type : std::is_same<typename Container::value_type, T> {};

	template<typename Container, typename = std::void_t<>>
	struct has_size : std::false_type {};

	template<typename Container>
	struct has_size<Container, std::void_t<decltype(std::declval<Container>().size())>> : std::true_type {};

	/// A type trait to check whether type \p Container has a member function \c size()
	template<typename Container>
	inline constexpr bool has_size_v = has_size<Container>::value;

	template<typename Container, typename = std::void_t<>>
	struct is_iterable : std::false_type {};

	template<typename Container>
	struct is_iterable<Container, std::void_t<decltype(*std::begin(std::declval<Container>())), decltype(std::end(std::declval<Container>()))>>
		: std::true_type {};

	/// A type trait to check whether type \p Container is a class type with a member type alias \c value_type equal to T and with begin() and end() methods.
	template<typename Container, typename T>
	inline constexpr bool is_iterable_container_with_matching_type_v =
		std::conjunction<std::is_class<Container>, has_value_type<Container>, is_iterable<Container>, has_matching_type<Container, T>>::value;

	/**
	 * @brief   Get index of given type in the variant
	 * @tparam  VariantType - any variant type
	 * @tparam  T - any type, if T is repeated in the variant, index of the first occurrence will be returned
	 * @tparam  index - implementation detail, do not specify explicitly
	 * @return  index of given type in the variant or out-of-bound value if the type is not a variant member
	 * @see     https://stackoverflow.com/questions/52303316/get-index-by-type-in-stdvariant
	 */
	template<typename VariantType, typename T, std::size_t index = 0>
	constexpr std::size_t variant_index() {
		// NOLINTNEXTLINE(bugprone-branch-clone): for some reason this did not work when first two branches were combined into one
		if constexpr (index >= std::variant_size_v<VariantType>) {
			return index;
		} else if (std::is_same_v<std::variant_alternative_t<index, VariantType>, T>) {
			return index;
		} else {
			return variant_index<VariantType, T, index + 1>();
		}
	}

	/**
	 * @brief 	Dummy function called on otherwise unused parameters to eliminate compiler warnings.
	 * @tparam 	Ts - variadic template parameter, any number of arbitrary types
	 */
	template<typename... Ts>
	void Unused(Ts&&... /* args */) {}

	/**
	 * @brief	Get a type that inherits from false_type and ignores the template parameter completely
	 * @tparam 	T - any type
	 */
	template<typename T>
	struct dependent_false : std::false_type {};

	/**
	 * @brief	Compile-time boolean constant false that "depends" on a template parameter.
	 * Useful utility for static_assert.
	 */
	template<typename T>
	inline constexpr bool dependent_false_v = dependent_false<T>::value;

	/// Utility structure that matches an MNumericArray data type with corresponding C++ type
	template<numericarray_data_t>
	struct [[maybe_unused]] NumericArrayFromEnum;

	/// @cond
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Bit8> {
		using type = std::int8_t;
		static constexpr const char* typeName = "Integer8";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_UBit8> {
		using type = std::uint8_t;
		static constexpr const char* typeName = "UnsignedInteger8";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Bit16> {
		using type = std::int16_t;
		static constexpr const char* typeName = "Integer16";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_UBit16> {
		using type = std::uint16_t;
		static constexpr const char* typeName = "UnsignedInteger16";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Bit32> {
		using type = std::int32_t;
		static constexpr const char* typeName = "Integer32";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_UBit32> {
		using type = std::uint32_t;
		static constexpr const char* typeName = "UnsignedInteger32";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Bit64> {
		using type = std::int64_t;
		static constexpr const char* typeName = "Integer64";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_UBit64> {
		using type = std::uint64_t;
		static constexpr const char* typeName = "UnsignedInteger64";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Real32> {
		using type = float;
		static constexpr const char* typeName = "Real32";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Real64> {
		using type = double;
		static constexpr const char* typeName = "Real64";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Complex_Real32> {
		using type = std::complex<float>;
		static constexpr const char* typeName = "ComplexReal32";
	};
	template<>
	struct NumericArrayFromEnum<MNumericArray_Type_Complex_Real64> {
		using type = std::complex<double>;
		static constexpr const char* typeName = "ComplexReal64";
	};
	/// @endcond

	/// Simple type alias to easily extract type from NumericArrayFromEnum
	template<numericarray_data_t rat>
	using NumericArrayTypeFromEnum = typename NumericArrayFromEnum<rat>::type;

	/// Small namespace for NumericArray related utilities
	namespace NA {
		/**
		 * @brief Possible methods of handling out-of-range data when converting a NumericArray to different type.
		 */
		enum class ConversionMethod {
			Check = MNumericArray_Convert_Check,
			ClipCheck = MNumericArray_Convert_Clip_Check,
			Coerce = MNumericArray_Convert_Coerce,
			ClipCoerce = MNumericArray_Convert_Clip_Coerce,
			Round = MNumericArray_Convert_Round,
			ClipRound = MNumericArray_Convert_Clip_Round,
			Scale = MNumericArray_Convert_Scale,
			ClipScale = MNumericArray_Convert_Clip_Scale,
		};

		/**
		 * Get name of the given MNumericArray type, e.g. MNumericArray_Type_Bit16 has name "UnsignedInteger16"
		 * @param t - an MNumericArray type
		 * @return a name (as used when creating NumericArrays in WL) of the specified MNumericArray type
		 */
		inline std::string typeToString(numericarray_data_t t) {
			switch (t) {
				case MNumericArray_Type_Undef: return "Undefined";
				case MNumericArray_Type_Bit8: return NumericArrayFromEnum<MNumericArray_Type_Bit8>::typeName;
				case MNumericArray_Type_UBit8: return NumericArrayFromEnum<MNumericArray_Type_UBit8>::typeName;
				case MNumericArray_Type_Bit16: return NumericArrayFromEnum<MNumericArray_Type_Bit16>::typeName;
				case MNumericArray_Type_UBit16: return NumericArrayFromEnum<MNumericArray_Type_UBit16>::typeName;
				case MNumericArray_Type_Bit32: return NumericArrayFromEnum<MNumericArray_Type_Bit32>::typeName;
				case MNumericArray_Type_UBit32: return NumericArrayFromEnum<MNumericArray_Type_UBit32>::typeName;
				case MNumericArray_Type_Bit64: return NumericArrayFromEnum<MNumericArray_Type_Bit64>::typeName;
				case MNumericArray_Type_UBit64: return NumericArrayFromEnum<MNumericArray_Type_UBit64>::typeName;
				case MNumericArray_Type_Real32: return NumericArrayFromEnum<MNumericArray_Type_Real32>::typeName;
				case MNumericArray_Type_Real64: return NumericArrayFromEnum<MNumericArray_Type_Real64>::typeName;
				case MNumericArray_Type_Complex_Real32: return NumericArrayFromEnum<MNumericArray_Type_Complex_Real32>::typeName;
				case MNumericArray_Type_Complex_Real64: return NumericArrayFromEnum<MNumericArray_Type_Complex_Real64>::typeName;
				default:
					// In V12.2 MNumericArray_Type_Real16 and MNumericArray_Type_Complex_Real16 have been introduced but they are not supported in the Kernel.
					// We add a default case to avoid compiler warnings.
					return "Undefined";
			}
			return "Undefined";
		}
	}	 // namespace NA

	/// Utility variable template that matches a C++ type with a corresponding MImage data type
	template<typename T>
	inline constexpr imagedata_t ImageType = MImage_Type_Undef;
	/// @cond
	template<>
	inline constexpr imagedata_t ImageType<int8_t> = MImage_Type_Bit;
	template<>
	inline constexpr imagedata_t ImageType<uint8_t> = MImage_Type_Bit8;
	template<>
	inline constexpr imagedata_t ImageType<uint16_t> = MImage_Type_Bit16;
	template<>
	inline constexpr imagedata_t ImageType<float> = MImage_Type_Real32;
	template<>
	inline constexpr imagedata_t ImageType<double> = MImage_Type_Real;
	/// @endcond

	/// Utility structure that matches a C++ type with a corresponding MNumericArray data type
	template<typename T>
	inline constexpr numericarray_data_t NumericArrayType = MNumericArray_Type_Undef;
	/// @cond
	template<>
	inline constexpr numericarray_data_t NumericArrayType<int8_t> = MNumericArray_Type_Bit8;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<uint8_t> = MNumericArray_Type_UBit8;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<int16_t> = MNumericArray_Type_Bit16;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<uint16_t> = MNumericArray_Type_UBit16;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<int32_t> = MNumericArray_Type_Bit32;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<uint32_t> = MNumericArray_Type_UBit32;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<int64_t> = MNumericArray_Type_Bit64;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<uint64_t> = MNumericArray_Type_UBit64;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<float> = MNumericArray_Type_Real32;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<double> = MNumericArray_Type_Real64;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<std::complex<float>> = MNumericArray_Type_Complex_Real32;
	template<>
	inline constexpr numericarray_data_t NumericArrayType<std::complex<double>> = MNumericArray_Type_Complex_Real64;
	/// @endcond

	/// Utility structure that matches a C++ type with a corresponding MTensor data type
	template<typename T>
	inline constexpr mint TensorType = MType_Undef;
	/// @cond
	template<>
	inline constexpr mint TensorType<mint> = MType_Integer;
	template<>
	inline constexpr mint TensorType<double> = MType_Real;
	template<>
	inline constexpr mint TensorType<std::complex<double>> = MType_Complex;
	/// @endcond

} /* namespace LLU */

#endif	  // LLU_UTILITIES_HPP
