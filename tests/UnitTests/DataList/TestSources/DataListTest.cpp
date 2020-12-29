/**
 * @file	DataListTest.cpp
 * @date	September 6, 2018
 * @author	rafalc
 * @brief	Source code for unit tests of DataStore and its wrapper DataList<T>.
 */

#include <iostream>
#include <list>
#include <string>

#include "wstp.h"

#include <LLU/Containers/Iterators/DataList.hpp>
#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/Utilities.hpp>
#include <LLU/WSTP/WSStream.hpp>

namespace WS = LLU::WS;
namespace LLErrorCode = LLU::ErrorCode;

using LLU::WSStream;
using LLU::DataList;
using LLU::GenericDataList;

/* Initialize Library */

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	return LLErrorCode::NoError;
}

/* Returns an input or a copy of an input */
LLU_LIBRARY_FUNCTION(PassDataStore) {
	auto dlIn = mngr.getDataList<LLU::NodeType::Any>(0);
	auto returnCopyQ = mngr.getBoolean(1);

	if (returnCopyQ) {
		auto dlOut = dlIn.clone();
		mngr.set(dlOut);
	} else {
		mngr.set(dlIn);
	}
}

/* Returns a DataStores carrying two input DataStores as nodes */
LLU_LIBRARY_FUNCTION(JoinDataStores) {
	auto ds1 = mngr.getGenericDataList(0);
	auto ds2 = mngr.getGenericDataList(1);
	auto returnCopyQ = mngr.getBoolean(2);

	DataList<GenericDataList> dsOut;
	if (returnCopyQ) {
		dsOut.push_back(ds1.clone());
		dsOut.push_back(ds2.clone());
	} else {
		dsOut.push_back(std::move(ds1));
		dsOut.push_back(std::move(ds2));
	}
	mngr.setDataList(dsOut);
}

/* Returns a copy of the input plus its own reference */
LLU_LIBRARY_FUNCTION(TestSelfReferencialDataStore) {
	auto dsIn = mngr.getGenericDataList(0);
	dsIn.push_back(LLU::NodeType::Any {std::in_place_type_t<GenericDataList>(), dsIn.getContainer(), LLU::Ownership::LibraryLink});
	mngr.set(dsIn);
}

/* Returns a empty DataStore */
LLU_LIBRARY_FUNCTION(EmptyDataStore) {
	GenericDataList ds;
	mngr.set(ds);
}

template<typename InContainer, typename OutContainer = InContainer>
void reverseListOfString(LLU::MArgumentManager& mngr) {
	using NodeT = LLU::NodeType::UTF8String;

	auto dsIn = mngr.get<InContainer>(0);
	OutContainer dsOut;

	for (auto node : dsIn) {
		std::string_view s;
		if constexpr (std::is_same_v<InContainer, DataList<NodeT>>) {
			s = node.value();
		} else {
			s = node.template as<NodeT>();
		}
		std::string reversed {s.rbegin(), s.rend()};	// create reversed copy
		dsOut.push_back(std::string_view(reversed));
	}

	mngr.set(dsOut);
}

/* Reverse each string in a list of strings using DataList */
LLU_LIBRARY_FUNCTION(ReverseListOfStrings) {
	reverseListOfString<DataList<std::string_view>>(mngr);
}

LLU_LIBRARY_FUNCTION(ReverseListOfStringsGenericOut) {
	reverseListOfString<DataList<std::string_view>, GenericDataList>(mngr);
}

LLU_LIBRARY_FUNCTION(ReverseListOfStringsGenericIn) {
	reverseListOfString<GenericDataList, DataList<std::string_view>>(mngr);
}

/* Reverse each string in a list of strings using GenericDataList */
LLU_LIBRARY_FUNCTION(ReverseListOfStringsGeneric) {
	reverseListOfString<GenericDataList>(mngr);
}

/* Reverse each string in a list of strings using raw DataStore */
LIBRARY_LINK_FUNCTION(ReverseListOfStringsLibraryLink) {
	auto errCode = LLErrorCode::NoError;
	DataStore ds_out = nullptr;
	try {
		/* Argument checking */
		if (Argc != 1) {
			throw std::runtime_error("Invalid number of args");
		}
		DataStore ds_in = MArgument_getDataStore(Args[0]); // NOLINT: deliberate C-style
		if (ds_in == nullptr) {
			throw std::runtime_error("Invalid input DataStore");
		}
		mint length = libData->ioLibraryFunctions->DataStore_getLength(ds_in);
		if (length <= 0) {
			throw std::runtime_error("Invalid length of input DataStore");
		}

		ds_out = libData->ioLibraryFunctions->createDataStore();
		if (ds_out == nullptr) {
			throw std::runtime_error("Invalid output DataStore");
		}

		DataStoreNode dsn = libData->ioLibraryFunctions->DataStore_getFirstNode(ds_in);
		while (dsn != nullptr) {
			MArgument data;
			if (libData->ioLibraryFunctions->DataStoreNode_getData(dsn, &data) != 0) {
				throw std::runtime_error("Could not get node data");
			}
			if (libData->ioLibraryFunctions->DataStoreNode_getDataType(dsn) != MType_UTF8String) {
				throw std::runtime_error("Node of invalid type in the DataStore");
			}
			dsn = libData->ioLibraryFunctions->DataStoreNode_getNextNode(dsn);
			std::string_view s {MArgument_getUTF8String(data)};
			std::string outStr(s.rbegin(), s.rend());	 // create reversed copy
			libData->ioLibraryFunctions->DataStore_addString(ds_out, outStr.data());
		}
		MArgument_setDataStore(Res, ds_out); // NOLINT: deliberate C-style
	} catch (const LLU::LibraryLinkError& e) {
		errCode = e.which();
		if (ds_out) {
			libData->ioLibraryFunctions->deleteDataStore(ds_out);
		}
	} catch (...) {
		errCode = LLErrorCode::FunctionError;
		if (ds_out) {
			libData->ioLibraryFunctions->deleteDataStore(ds_out);
		}
	}
	return errCode;
}

/* Reverse each string in a list of strings using WSTP */
LIBRARY_WSTP_FUNCTION(ReverseListOfStringsWSTP) {
	auto err = LLErrorCode::NoError;
	try {
		WSStream<WS::Encoding::UTF8> ml {wsl, 1};
		std::vector<std::string> listOfStrings;
		ml >> listOfStrings;

		ml << WS::List(static_cast<int>(listOfStrings.size()));
		for (const auto& s : listOfStrings) {
			std::string outStr(s.rbegin(), s.rend());	 // create reversed copy
			ml << outStr;
		}
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}

LLU_LIBRARY_FUNCTION(SeparateKeysAndValues) {
	auto dsIn = mngr.getDataList<LLU::NodeType::Complex>(0);
	DataList<LLU::NodeType::UTF8String> keys;
	DataList<LLU::NodeType::Complex> values;

	for (auto [name, value] : dsIn) {
		keys.push_back(name);
		values.push_back(value);
	}

	DataList<GenericDataList> dsOut;
	dsOut.push_back("Keys", std::move(keys));
	dsOut.push_back("Values", std::move(values));

	mngr.set(dsOut);
}

LLU_LIBRARY_FUNCTION(SeparateKeysAndValuesViaAdaptors) {
	auto dsIn = mngr.getDataList<LLU::NodeType::Complex>(0);

	DataList<LLU::NodeType::UTF8String> keys;
	for (auto name : LLU::NameAdaptor {dsIn}) {
		keys.push_back(name);
	}

	DataList<LLU::NodeType::Complex> values;
	for (auto value : LLU::ValueAdaptor {dsIn}) {
		values.push_back(value);
	}

	DataList<GenericDataList> dsOut;
	dsOut.push_back("Keys", std::move(keys));
	dsOut.push_back("Values", std::move(values));

	mngr.set(dsOut);
}

LLU_LIBRARY_FUNCTION(GetKeys) {
	auto dsIn = mngr.getDataList<LLU::NodeType::Any>(0);
	DataList<std::string_view> keys;

	for (auto it = dsIn.nameBegin(); it != dsIn.nameEnd(); ++it) {
		keys.push_back(*it);
	}

	auto names = dsIn.names();
	if (!std::equal(names.cbegin(), names.cend(), keys.cbegin(), [](const auto& name, const auto& key) {
			return std::string_view {name} == key.value();
		})) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}

	mngr.setDataList(keys);
}

LLU_LIBRARY_FUNCTION(GetValuesReversed) {
	auto dsIn = mngr.getDataList<LLU::NodeType::Any>(0);
	DataList<LLU::NodeType::Any> valuesRev;

	auto values = dsIn.values();
	std::move(values.rbegin(), values.rend(), std::back_inserter(valuesRev));

	mngr.setDataList(valuesRev);
}

LLU_LIBRARY_FUNCTION(FrameDims) {
	auto dsIn = mngr.getDataList<LLU::GenericImage>(0);

	LLU::NumericArray<std::uint64_t> dims {0, {dsIn.length(), 2}};
	mint dimsIndex = 0;

	for (auto imgNode : dsIn) {
		dims[dimsIndex++] = static_cast<std::uint64_t>(imgNode.value().rows());
		dims[dimsIndex++] = static_cast<std::uint64_t>(imgNode.value().columns());
	}
	mngr.setNumericArray(dims);
}

LLU_LIBRARY_FUNCTION(StringsThroughVectorReversed) {
	auto dsIn = mngr.getDataList<std::string_view>(0);

	auto vec = dsIn.toVector();

	DataList<std::string_view> dsOut;
	std::transform(vec.rbegin(), vec.rend(), std::back_inserter(dsOut), [](auto node) { return node.value(); });

	mngr.setDataList(dsOut);
}

LLU_LIBRARY_FUNCTION(IntsToNumericArray) {
	auto dsIn = mngr.getDataList<mint>(0);

	LLU::NumericArray<mint> ra {dsIn.valueBegin(), dsIn.valueEnd(), {dsIn.length()}};

	mngr.setNumericArray(ra);
}

LLU_LIBRARY_FUNCTION(GetLength) {
	auto dsIn = mngr.getGenericDataList(0);
	mngr.setInteger(dsIn.length());
}

LLU_LIBRARY_FUNCTION(CheckSizeChange) {
	auto n = mngr.getInteger<mint>(0);
	DataList<mint> dsInt;
	DataList<LLU::NodeType::Any> dsArg;
	GenericDataList gds;
	for (mint i = 0; i < n; ++i) {
		dsInt.push_back(i);
		dsArg.push_back(i);
		gds.push_back(i);
	}
	LLU::Tensor<mint> res({dsInt.length(), dsArg.length(), gds.length()});
	mngr.setTensor(res);
}

LLU_LIBRARY_FUNCTION(PullAndPush) {
	using LLU::MArgumentType;
	using LLU::Argument::toPrimitiveType;

	auto dsIn = mngr.getDataList<LLU::NodeType::Any>(0);
	auto values = dsIn.values();
	GenericDataList dsOut;

	// get and push Boolean
	auto b = *std::get_if<bool>(&values[0]);
	auto rawB = static_cast<mbool>(b);

	dsOut.push_back(b);
	dsOut.push_back(rawB);
	dsOut.push_back<MArgumentType::Boolean>("bool", b);
	dsOut.push_back<MArgumentType::Boolean>("mbool", rawB);

	// get and push Integer
	auto i = *std::get_if<mint>(&values[1]);
	dsOut.push_back(i);
	dsOut.push_back<MArgumentType::Integer>("mint", i);

	// get and push Real
	auto d = *std::get_if<double>(&values[2]);
	dsOut.push_back(d);
	dsOut.push_back<MArgumentType::Real>("mreal", d);

	// get and push Complex
	auto c = *std::get_if<std::complex<double>>(&values[3]);
	auto rawC = toPrimitiveType<MArgumentType::Complex>(c);
	dsOut.push_back(c);
	dsOut.push_back(rawC);
	dsOut.push_back<MArgumentType::Complex>("complex", c);
	dsOut.push_back<MArgumentType::Complex>("mcomplex", rawC);

	// get and push Tensor
	auto& t = *std::get_if<LLU::GenericTensor>(&values[4]);
	[[maybe_unused]] auto *rawT = toPrimitiveType<MArgumentType::Tensor>(t);
	dsOut.push_back(t.clone());
	//dsOut.push_back(rawT); - compile time error due to a LibraryLink limitation
	dsOut.push_back<MArgumentType::Tensor>("Tensor", std::move(t));
	//dsOut.push_back<MArgumentType::Tensor>("MTensor", rawT); // this container has already been pushed to the dsOut one line above

	// get and push SparseArray
	auto& sa = *std::get_if<MSparseArray>(&values[5]);
	dsOut.push_back(sa);
	dsOut.push_back<MArgumentType::SparseArray>("MSparseArray", sa);

	// get and push NumericArray
	auto& na = *std::get_if<LLU::GenericNumericArray>(&values[6]);
	[[maybe_unused]] auto *rawNA = toPrimitiveType<MArgumentType::NumericArray>(na);
	dsOut.push_back(na.clone());
	//dsOut.push_back(rawNA); - compile time error due to a LibraryLink limitation
	dsOut.push_back<MArgumentType::NumericArray>("NumericArray", std::move(na));
	//dsOut.push_back<MArgumentType::NumericArray>("MNumericArray", rawNA);  // this container has already been pushed to the dsOut one line above

	// get and push Image
	auto& im = *std::get_if<LLU::GenericImage>(&values[7]);
	[[maybe_unused]] auto *rawIm = toPrimitiveType<MArgumentType::Image>(im);
	dsOut.push_back(im.clone());
	//dsOut.push_back(rawIm);
	dsOut.push_back<MArgumentType::Image>("Image", std::move(im));
	//dsOut.push_back<MArgumentType::Image>("MImage", rawIm);

	// get and push String
	auto str = *std::get_if<std::string_view>(&values[8]);
	auto *rawStr = toPrimitiveType<MArgumentType::UTF8String>(str);
	dsOut.push_back(str);
	dsOut.push_back(rawStr);
	dsOut.push_back<MArgumentType::UTF8String>("String", str);
	dsOut.push_back<MArgumentType::UTF8String>("RawString", rawStr);

	// get and push DataStore
	auto& ds = *std::get_if<LLU::GenericDataList>(&values[9]);
	[[maybe_unused]] auto *rawDS = toPrimitiveType<MArgumentType::DataStore>(ds);
	dsOut.push_back(ds.clone());
	//dsOut.push_back(rawDS);
	dsOut.push_back<MArgumentType::DataStore>("DataList", std::move(ds));
	// never add the same raw container to a DataStore multiple times, this will not work in top-level
	//dsOut.push_back<MArgumentType::DataStore>("DataStore", rawDS);

	mngr.set(dsOut);
}

template<typename T>
T getValueAndAdvance(GenericDataList::iterator& node) {
	return (*node++).as<T>();
}

LLU_LIBRARY_FUNCTION(PullAndPush2) {
	using LLU::MArgumentType;
	using LLU::Argument::toPrimitiveType;

	auto dsIn = mngr.getGenericDataList(0);
	DataList<LLU::NodeType::Any> dsOut;

	auto node = dsIn.begin();

	// get and push Boolean
	auto b = (node++)->as<bool>();
	dsOut.push_back(b);

	// get and push Integer
	auto i = (node++)->as<mint>();
	dsOut.push_back(i);

	// get and push Real
	auto d = (node++)->as<double>();
	dsOut.push_back(d);

	// get and push Complex
	auto c = (node++)->as<std::complex<double>>();
	dsOut.push_back(c);

	// get and push Tensor
	auto t = (node++)->as<LLU::GenericTensor>();
	auto *rawT = toPrimitiveType<MArgumentType::Tensor>(t);
	dsOut.push_back(t.clone());
	// NOLINTNEXTLINE: deliberate example of a shady code
	dsOut.push_back("Tensor", rawT); // rawT is a pointer type, it gets converted to bool and send as Boolean node

	// get and push SparseArray
	auto *sa = (node++)->as<MSparseArray>();
	dsOut.push_back(sa);

	// get and push NumericArray
	auto na = (node++)->as<LLU::GenericNumericArray>();
	auto *rawNA = toPrimitiveType<MArgumentType::NumericArray>(na);
	dsOut.push_back(na.clone());
	// NOLINTNEXTLINE: deliberate example of a shady code - surprising implicit pointer -> bool conversion
	dsOut.push_back("NumericArray", rawNA);

	// get and push Image
	auto im = (node++)->as<LLU::GenericImage>();
	auto *rawIm = toPrimitiveType<MArgumentType::Image>(im);
	dsOut.push_back(im.clone());
	// NOLINTNEXTLINE: deliberate example of a shady code - surprising implicit pointer -> bool conversion
	dsOut.push_back("Image", rawIm);

	// get and push String
	auto str = (node++)->as<std::string_view>();
	auto *rawStr = toPrimitiveType<MArgumentType::UTF8String>(str);
	dsOut.push_back(str);
	dsOut.push_back("String", rawStr);

	// get and push DataStore
	auto ds = (node++)->as<LLU::GenericDataList>();
	auto *rawDS = toPrimitiveType<MArgumentType::DataStore>(ds);
	dsOut.push_back(ds.clone());
	// NOLINTNEXTLINE: deliberate example of a shady code - surprising implicit pointer -> bool conversion
	dsOut.push_back("DataList", rawDS);

	mngr.set(dsOut);
}

LLU_LIBRARY_FUNCTION(FromInitList) {
	using namespace std::complex_literals;
	GenericDataList res;

	res.push_back(DataList<LLU::NodeType::Boolean> {{"a", 2}, {"b", false}});
	res.push_back(DataList<LLU::NodeType::Integer> {2, 3, 5, 7, 11});
	res.push_back(DataList<LLU::NodeType::Real> {{"a", 2.34}, {"b", 3.14}});
	res.push_back(DataList<LLU::NodeType::Complex> {2. + 3i, 3, 5.1 - 1.23i, 7, 11i});
	res.push_back(DataList<LLU::NodeType::UTF8String> {{"a","x"},{"b","y"}});

	mngr.set(res);
}