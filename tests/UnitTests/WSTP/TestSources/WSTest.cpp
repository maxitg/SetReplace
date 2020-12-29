/**
 * @file	WSTest.cpp
 * @date	Nov 23, 2017
 * @author	rafalc
 * @brief	Source code for WSTPStream unit tests.
 */

#include <LLU/NoMinMaxWindows.h>

#include <algorithm>
#include <iostream>
#include <map>
#include <random>
#include <regex>
#include <set>
#include <string>
#include <vector>

#include <LLU/LibraryData.h>
#include <LLU/ErrorLog/LibraryLinkError.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/WSTP/WSStream.hpp>

namespace WS = LLU::WS;
using LLU::WSStream;
using WSTPStream = WSStream<WS::Encoding::UTF8>;

template<typename T>
void readAndWriteScalar(WSTPStream& m) {
	T x;
	m >> x;
	m << x;
}

template<typename T>
void readAndWriteScalarMax(WSTPStream& m) {
	T x;
	m >> x;
	m << (std::numeric_limits<T>::max)();
}

//
// Scalars
//
LLU_WSTP_FUNCTION(SameInts) {
	WSTPStream m(wsl, "List", 4);
	m << WS::List(4);
	readAndWriteScalar<unsigned char>(m);
	readAndWriteScalar<short>(m);
	readAndWriteScalar<int>(m);
	readAndWriteScalar<wsint64>(m);
}

LLU_WSTP_FUNCTION(MaxInts) {
	WSTPStream m(wsl, "List", 4);
	m << WS::List(4);
	readAndWriteScalarMax<unsigned char>(m);
	readAndWriteScalarMax<short>(m);
	readAndWriteScalarMax<int>(m);
	readAndWriteScalarMax<wsint64>(m);
}

LLU_WSTP_FUNCTION(WriteMint) {
	WSTPStream m(wsl);
	WS::List l;
	m >> l;
	mint i = -1;
	m << i;
}

LLU_WSTP_FUNCTION(SameFloats) {
	WSTPStream m(wsl, "List", 2);
	m << WS::List(2);
	readAndWriteScalar<float>(m);
	readAndWriteScalar<double>(m);
}

LLU_WSTP_FUNCTION(BoolAnd) {
	WSTPStream ml(wsl);

	WS::List l;
	ml >> l;

	// Read all bools in a loop and calculate conjunction. No short-circuit
	bool res = true;
	for (auto i = 0; i < l.getArgc(); ++i) {
		bool b {};
		ml >> b;
		res &= b;
	}

	ml << WS::NewPacket << res << WS::EndPacket;
}

//
// Lists
//

template<class T>
void getAndPut(WSTPStream& m) {
	T t;
	m >> t;
	m << t;
}

template<typename T>
void reverseList(WSTPStream& m) {
	WS::ListData<T> l;
	m >> l;

	auto listLen = l.get_deleter().getLength();
	std::vector<T> result(listLen);
	std::reverse_copy(l.get(), l.get() + listLen, std::begin(result));
	m << result;
}

LLU_WSTP_FUNCTION(GetReversed8) {
	WSTPStream ml(wsl, "List", 1);
	reverseList<unsigned char>(ml);
}

LLU_WSTP_FUNCTION(GetReversed16) {
	WSTPStream ml(wsl, "List", 1);
	reverseList<short>(ml);
}

LLU_WSTP_FUNCTION(GetReversed32) {
	WSTPStream ml(wsl, "List", 1);
	reverseList<int>(ml);
}

LLU_WSTP_FUNCTION(GetReversed64) {
	WSTPStream ml(wsl, "List", 1);
	reverseList<wsint64>(ml);
}

LLU_WSTP_FUNCTION(GetReversedDouble) {
	WSTPStream ml(wsl, "List", 1);
	reverseList<double>(ml);
}

LLU_WSTP_FUNCTION(GetFloatList) {
	WSTPStream ml(wsl, "List", 1);
	getAndPut<WS::ListData<float>>(ml);
}

//
// Arrays
//

LLU_WSTP_FUNCTION(GetSame8) {
	WSTPStream ml(wsl, "List", 1);
	getAndPut<WS::ArrayData<unsigned char>>(ml);
}

LLU_WSTP_FUNCTION(GetSame16) {
	WSTPStream ml(wsl, "List", 1);
	getAndPut<WS::ArrayData<short>>(ml);
}

LLU_WSTP_FUNCTION(GetSame32) {
	WSTPStream ml(wsl, "List", 1);
	getAndPut<WS::ArrayData<int>>(ml);
}

LLU_WSTP_FUNCTION(GetSame64) {
	WSTPStream ml(wsl, "List", 1);
	getAndPut<WS::ArrayData<wsint64>>(ml);
}

LLU_WSTP_FUNCTION(GetSameDouble) {
	WSTPStream ml(wsl, "List", 1);
	getAndPut<WS::ArrayData<double>>(ml);
}

template<typename T>
void reshapeArray(WSTPStream& m) {
	WS::ArrayData<T> a;
	m >> a;

	auto rank = a.get_deleter().getRank();
	if (rank >= 2) {
		auto* dims = a.get_deleter().getDims();
		std::swap(*std::next(dims, rank - 2), *std::next(dims, rank - 1));
	}
	m << a;
}

LLU_WSTP_FUNCTION(Reshape8) {
	WSTPStream ml(wsl, "List", 1);
	reshapeArray<unsigned char>(ml);
}

LLU_WSTP_FUNCTION(Reshape16) {
	WSTPStream ml(wsl, "List", 1);
	reshapeArray<short>(ml);
}

LLU_WSTP_FUNCTION(Reshape32) {
	WSTPStream ml(wsl, "List", 1);
	reshapeArray<int>(ml);
}

LLU_WSTP_FUNCTION(Reshape64) {
	WSTPStream ml(wsl, "List", 1);
	reshapeArray<wsint64>(ml);
}

LLU_WSTP_FUNCTION(ReshapeDouble) {
	WSTPStream ml(wsl, "List", 1);
	reshapeArray<double>(ml);
}

LLU_WSTP_FUNCTION(ComplexToList) {
	WSTPStream ml(wsl, "List", 1);
	WS::ArrayData<double> a;
	ml >> a;

	auto rank = a.get_deleter().getRank();
	char** heads = a.get_deleter().getHeads();
	if (rank >= 1) {
		using namespace std::string_literals;
		auto listHead = "List"s;
		std::vector<const char*> newHeads(heads, std::next(heads, rank));
		newHeads[rank - 1] = listHead.c_str();
		WS::PutArray<double>::put(wsl, a.get(), a.get_deleter().getDims(), newHeads.data(), rank);
	} else {
		ml << a;
	}
}

LLU_WSTP_FUNCTION(ReceiveAndFreeArray) {
	WSTPStream ml(wsl, "List", 1);
	WS::ArrayData<double> a;
	ml >> a;
	ml << WS::Null << WS::EndPacket;
}

//
// Strings
//

template<WS::Encoding EIn, WS::Encoding EOut>
void repeatString(WSStream<EIn, EOut>& ml) {
	std::string s;
	ml >> s;
	ml << s + s;
}

// Specialize for UTF16 and UTF32 because WSTP prepends BOM to the string
template<>
void repeatString(WSStream<WS::Encoding::UTF16>& ml) {
	std::basic_string<unsigned short> s;
	ml >> s;
	auto t = s;
	ml << t + s.erase(0, 1);
}

template<>
void repeatString(WSStream<WS::Encoding::UTF32>& ml) {
	std::basic_string<unsigned int> s;
	ml >> s;
	auto t = s;
	ml << t + s.erase(0, 1);
}

LLU_WSTP_FUNCTION(RepeatString) {
	WSStream<WS::Encoding::Native> ml(wsl, "List", 1);
	repeatString(ml);
}

LLU_WSTP_FUNCTION(RepeatUTF8) {
	WSStream<WS::Encoding::UTF8> ml(wsl, "List", 1);
	repeatString(ml);
}

LLU_WSTP_FUNCTION(RepeatUTF16) {
	WSStream<WS::Encoding::UTF16> ml(wsl, "List", 1);
	repeatString(ml);
}

LLU_WSTP_FUNCTION(RepeatUTF32) {
	WSStream<WS::Encoding::UTF32> ml(wsl, "List", 1);
	repeatString(ml);
}

template<WS::Encoding E>
void appendString(WSStream<E>& ml) {
	WS::StringType<E> s;
	ml >> s;
	WS::StringType<E> appendix {{'\a', '\b', '\f', '\r', '\n', '\t', '\v', '\\', '\'', '\"', '\?'}};
	ml << s + appendix;
}

template<>
void appendString(WSStream<WS::Encoding::Native>& ml) {
	std::string s;
	ml >> s;
	std::string appendix {{'\a', '\b', '\f', '\r', '\n', '\t', '\v', '\\', '\\', '\'', '\"', '\?'}};
	ml << s + appendix;
}

LLU_WSTP_FUNCTION(AppendString) {
	WSStream<WS::Encoding::Native> ml(wsl, "List", 1);
	appendString(ml);
}

LLU_WSTP_FUNCTION(AppendUTF8) {
	WSStream<WS::Encoding::UTF8> ml(wsl, "List", 1);
	appendString(ml);
}

LLU_WSTP_FUNCTION(AppendUTF16) {
	WSStream<WS::Encoding::UTF16> ml(wsl, "List", 1);
	appendString(ml);
}

LLU_WSTP_FUNCTION(AppendUTF32) {
	WSStream<WS::Encoding::UTF32> ml(wsl, "List", 1);
	appendString(ml);
}

LLU_WSTP_FUNCTION(ReceiveAndFreeString) {
	WSTPStream ml(wsl, "List", 1);
	WS::StringData<WS::Encoding::Native> s;
	ml >> s;
	ml << WS::Null << WS::EndPacket;
}

LLU_WSTP_FUNCTION(GetAndPutUTF8) {
	WSStream<WS::Encoding::UTF8> ml(wsl, "List", 2);

	WS::StringData<WS::Encoding::UTF8> sUChar;
	ml >> sUChar;

	std::cout << "Unsigned char string bytes: ";
	for (int i = 0; i < sUChar.get_deleter().getLength(); ++i) {
		std::cout << std::to_string(+sUChar[i]) << " ";
	}
	std::cout << std::endl;

	std::string sChar;
	ml >> sChar;

	std::cout << sChar << std::endl;

	ml << R"(This will be sent as UTF8 encoded string. No need to escape backslashes \o/. Some weird characters: ą©łóßµ)" << WS::EndPacket;
}

//
// Symbols and Arbitrary Functions
//

LLU_WSTP_FUNCTION(GetList) {
	WSStream<WS::Encoding::Byte> ml(wsl, "List", 0);
	ml << WS::List(5);
	ml << std::vector<int> {1, 2, 3} << WS::Missing() << WS::putAs<WS::Encoding::UTF8>(std::vector<float> {1.5, 2.5, 3.5})
	   << WS::putAs<WS::Encoding::UTF8>("Hello!") << WS::Missing("Deal with it");
	ml << WS::EndPacket;
}

LLU_WSTP_FUNCTION(ReverseSymbolsOrder) {
	WSTPStream ml(wsl);
	WS::List l;
	ml >> l;

	// use unique_ptr only to test if WSTPStream handles it correctly
	std::vector<std::unique_ptr<WS::Symbol>> v;

	// Read all symbols in a loop
	for (auto i = 0; i < l.getArgc(); ++i) {
		WS::Symbol s;
		ml >> s;
		v.push_back(std::make_unique<WS::Symbol>(std::move(s)));
	}

	ml << WS::List(l.getArgc());
	for (auto it = v.crbegin(); it != v.crend(); ++it) {
		ml << *it;
	}
	ml << WS::EndPacket;
}

LLU_WSTP_FUNCTION(TakeLibraryFunction) {
	WSStream<WS::Encoding::UTF8> ml(wsl, "List", 1);
	WS::Function llf {"LibraryFunction", 3};
	ml >> llf;

	std::string libDir;
	ml >> libDir;

	std::string fname;
	ml >> fname;

	WS::Symbol s {"LinkObject"};
	ml >> s;

	ml << WS::NewPacket << llf << libDir << "ReverseSymbolsOrder" << s << WS::EndPacket;
}

LLU_WSTP_FUNCTION(GetSet) {
	WSStream<WS::Encoding::UTF8> ml(wsl);
	WS::List l;
	ml >> l;

	std::set<std::string> ss;
	WS::List innerL;
	ml >> innerL;
	for (auto i = 0; i < innerL.getArgc(); ++i) {
		std::string s;
		ml >> s;
		std::cout << s << std::endl;
		ss.insert(std::move(s));
	}

	if (l.getArgc() == 2) {	   // send with custom head
		std::string head;
		ml >> head;
		ml.sendRange(ss.cbegin(), ss.cend(), head);
	} else {
		ml << ss;
	}

	ml << WS::EndPacket;
}

//
// Associations/Maps
//

LLU_WSTP_FUNCTION(ReadNestedMap) {
	WSStream<WS::Encoding::Byte> ml(wsl, "List", 1);

	std::map<std::string, std::map<int, std::vector<double>>> myNestedMap;

	ml >> WS::getAs<WS::Encoding::UTF8>(myNestedMap);

	for (auto& outerRule : myNestedMap) {
		const auto& outerKey = outerRule.first;
		auto& innerMap = outerRule.second;
		for (auto& innerRule : innerMap) {
			auto& innerMapVal = innerRule.second;
			if (outerKey == "Negate") {
				std::transform(innerMapVal.cbegin(), innerMapVal.cend(), innerMapVal.begin(), std::negate<>());
			} else if (outerKey == "Add") {
				std::transform(innerMapVal.cbegin(), innerMapVal.cend(), innerMapVal.begin(), [&innerRule](auto d) { return d + innerRule.first; });
			} else if (outerKey == "Multiply") {
				std::transform(innerMapVal.cbegin(), innerMapVal.cend(), innerMapVal.begin(), [&innerRule](auto d) { return d * innerRule.first; });
			}
		}
	}

	ml << WS::putAs<WS::Encoding::UTF8>(myNestedMap);
}

//
// BeginExpr - DropExpr - EndExpr
//

LLU_WSTP_FUNCTION(UnknownLengthList) {
	WSTPStream ml(wsl, 1);

	int modulus = 0;
	ml >> modulus;

	std::random_device rd;
	std::mt19937 gen {rd()};
	std::uniform_int_distribution<> distr(0, std::max(1'000'000, modulus + 1));

	ml << WS::BeginExpr("List");

	int r = 0;
	while ((r = distr(gen)) % modulus != 0) {
		ml << r;
	}
	ml << WS::EndExpr();
}

LLU_WSTP_FUNCTION(RaggedArray) {
	WSTPStream ml(wsl, 1);

	int len = 0;
	ml >> len;

	ml << WS::BeginExpr("List");
	for (int i = 0; i < len; ++i) {
		ml << WS::BeginExpr("List");
		for (int j = 0; j < i; ++j) {
			ml << j;
		}
		ml << WS::EndExpr();
	}
	ml << WS::EndExpr();
}

LLU_WSTP_FUNCTION(FactorsOrFailed) {
	WSTPStream ml(wsl, 1);

	std::vector<int> numbers;
	ml >> numbers;

	ml << WS::BeginExpr("Association");
	for (auto&& n : numbers) {
		ml << WS::Rule << n;
		ml << WS::BeginExpr("List");
		int divisors = 0;
		for (int j = 1; j <= n; ++j) {
			if (n % j == 0) {
				if (divisors < 15) {
					ml << j;
					divisors++;
				} else {
					ml << WS::DropExpr();
					ml << WS::Symbol("$Failed");	// $Failed is now sent to the "parent" loopback link
					break;
				}
			}
		}
		ml << WS::EndExpr();
	}
	ml << WS::EndExpr();
}

LLU_WSTP_FUNCTION(Empty) {
	WSTPStream ml(wsl, 1);

	std::string head;
	ml >> head;

	ml << WS::BeginExpr(head);
	ml << WS::EndExpr();
}

LLU_WSTP_FUNCTION(ListOfStringsTiming) {

	WSTPStream ml(wsl, 2);

	std::vector<std::string> listOfStrings;
	ml >> listOfStrings;

	bool useBeginExpr {};
	ml >> useBeginExpr;

	constexpr int repetitions = 100;
	useBeginExpr ? (ml << WS::BeginExpr("List")) : (ml << WS::List(static_cast<int>(repetitions * listOfStrings.size())));

	for (int i = 0; i < repetitions; ++i) {
		for (auto&& s : listOfStrings) {
			ml << s;
		}
	}

	if (useBeginExpr) {
		ml << WS::EndExpr();
	}

	ml << WS::EndPacket;
}
