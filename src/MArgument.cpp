/**
 * @file	MArgument.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	September 03, 2018
 * @brief	Specializations of PrimitiveWrapper class template members.
 */

#include "LLU/MArgument.h"

#include "LLU/ErrorLog/ErrorManager.h"

namespace LLU {
/// @cond
#define LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(ArgType, MArgGetPrefix, MArgSetPrefix, DSAddNamed, DSAdd)      \
	template<>                                                                                                             \
	auto PrimitiveWrapper<MArgumentType::ArgType>::get()->value_type& {                                                    \
		return MArgGetPrefix##ArgType(arg);                                                                                \
	}                                                                                                                      \
	template<>                                                                                                             \
	auto PrimitiveWrapper<MArgumentType::ArgType>::get() const->const value_type& {                                        \
		return MArgGetPrefix##ArgType(arg);                                                                                \
	}                                                                                                                      \
	template<>                                                                                                             \
	void PrimitiveWrapper<MArgumentType::ArgType>::addDataStoreNode(DataStore ds, std::string_view name, value_type val) { \
		LibraryData::DataStoreAPI()->DataStore_##DSAddNamed(ds, const_cast<char*>(name.data()), val);                      \
	}                                                                                                                      \
	template<>                                                                                                             \
	void PrimitiveWrapper<MArgumentType::ArgType>::addDataStoreNode(DataStore ds, value_type val) {                        \
		LibraryData::DataStoreAPI()->DataStore_##DSAdd(ds, val);                                                           \
	}                                                                                                                      \
	template<>                                                                                                             \
	auto PrimitiveWrapper<MArgumentType::ArgType>::getAddress() const->value_type* {                                       \
		return MArgGetPrefix##ArgType##Address(arg);                                                                       \
	}                                                                                                                      \
	template<>                                                                                                             \
	void PrimitiveWrapper<MArgumentType::ArgType>::set(value_type newValue) {                                              \
		MArgSetPrefix##ArgType(arg, newValue);                                                                             \
	}

	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast): const_cast forced by LibraryLink API
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(Boolean, MArgument_get, MArgument_set, addNamedBoolean, addBoolean)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(Integer, MArgument_get, MArgument_set, addNamedInteger, addInteger)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(Real, MArgument_get, MArgument_set, addNamedReal, addReal)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(Complex, MArgument_get, MArgument_set, addNamedComplex, addComplex)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast, cppcoreguidelines-pro-type-cstyle-cast): c-style cast used in a macro in WolframIOLibraryFunctions.h
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(DataStore, MArgument_get, MArgument_set, addNamedDataStore, addDataStore)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(UTF8String, MArgument_get, MArgument_set, addNamedString, addString)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(Tensor, MArgument_getM, MArgument_setM, addNamedMTensor, addMTensor)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(SparseArray, MArgument_getM, MArgument_setM, addNamedMSparseArray, addMSparseArray)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(NumericArray, MArgument_getM, MArgument_setM, addNamedMNumericArray, addMNumericArray)
	//NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
	LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS(Image, MArgument_getM, MArgument_setM, addNamedMImage, addMImage)

#undef LLU_ARGUMENT_DEFINE_SPECIALIZATIONS_OF_MEMBER_FUNCTIONS

	template<>
	auto PrimitiveWrapper<MArgumentType::MArgument>::get() -> typename PrimitiveWrapper::value_type& {
		return arg;
	}
	template<>
	auto PrimitiveWrapper<MArgumentType::MArgument>::get() const -> const typename PrimitiveWrapper::value_type& {
		return arg;
	}
	template<>
	auto PrimitiveWrapper<MArgumentType::MArgument>::getAddress() const -> typename PrimitiveWrapper::value_type* {
		return &arg;
	}
	template<>
	void PrimitiveWrapper<MArgumentType::MArgument>::set(typename PrimitiveWrapper::value_type newValue) {
		arg = newValue;
	}
	template<>
	void PrimitiveWrapper<MArgumentType::MArgument>::addToDataStore(DataStore ds, const std::string& name, MArgumentType actualType) const {
		switch (actualType) {
			case MArgumentType::MArgument: ErrorManager::throwException(ErrorName::ArgumentAddNodeMArgument);
			case MArgumentType::Boolean: PrimitiveWrapper<MArgumentType::Boolean>(arg).addToDataStore(ds, name); break;
			case MArgumentType::Integer: PrimitiveWrapper<MArgumentType::Integer>(arg).addToDataStore(ds, name); break;
			case MArgumentType::Real: PrimitiveWrapper<MArgumentType::Real>(arg).addToDataStore(ds, name); break;
			case MArgumentType::Complex: PrimitiveWrapper<MArgumentType::Complex>(arg).addToDataStore(ds, name); break;
			case MArgumentType::DataStore: PrimitiveWrapper<MArgumentType::DataStore>(arg).addToDataStore(ds, name); break;
			case MArgumentType::UTF8String: PrimitiveWrapper<MArgumentType::UTF8String>(arg).addToDataStore(ds, name); break;
			case MArgumentType::Tensor: PrimitiveWrapper<MArgumentType::Tensor>(arg).addToDataStore(ds, name); break;
			case MArgumentType::SparseArray: PrimitiveWrapper<MArgumentType::SparseArray>(arg).addToDataStore(ds, name); break;
			case MArgumentType::NumericArray: PrimitiveWrapper<MArgumentType::NumericArray>(arg).addToDataStore(ds, name); break;
			case MArgumentType::Image: PrimitiveWrapper<MArgumentType::Image>(arg).addToDataStore(ds, name); break;
		}
	}
/// @endcond
}  // namespace LLU