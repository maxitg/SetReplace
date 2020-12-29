/**
 * @file	MArgumentManagerTest.cpp
 * @author	rafalc
 * @brief	Source code for unit tests of MArgumentManager
 */
#include <functional>
#include <iostream>
#include <tuple>

#include <LLU/Containers/Iterators/DataList.hpp>
#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	return LLU::ErrorCode::NoError;
}

// Simple case for custom MArgument types that correspond to a single basic argument type - directly specialize MArgumentManager::get.
namespace LLU {
	template<>
	float MArgumentManager::get<float>(size_type index) const {
		return static_cast<float>(get<double>(index));
	}

	template<>
	void MArgumentManager::set<float>(const float& arg) {
		set(static_cast<double>(arg));
	}
}	 // namespace LLU

LLU_LIBRARY_FUNCTION(AsFloat) {
	auto [f1] = mngr.getTuple<float>();
	auto f2 = mngr.get<float>(0);
	if (f1 != f2) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}
	mngr.set(f1);
}

LLU_LIBRARY_FUNCTION(Transform) {
	auto [a, n, b] = mngr.getTuple<float, mint, float>();
	mngr.set(a * n + b);
}

LLU_LIBRARY_FUNCTION(DescribePerson) {
	auto [name, age, height] = mngr.getTuple<std::string, uint8_t, double>();
	mngr.set(name + " is " + std::to_string(age) + " years old and " + std::to_string(height) + "m tall.");
}

struct Person {
	Person(std::string n, uint8_t a, double h) : name {std::move(n)}, age {a}, height {h} {}

	std::string name;
	uint8_t age;
	double height;

	[[nodiscard]] std::string description() const {
		return name + " is " + std::to_string(age) + " years old and " + std::to_string(height) + "m tall.";
	}
};

namespace LLU {
	// Tell LLU that Person corresponds to 3 "basic" types: String, Integer and Real. When you try to read Person as argument, LLU will read 3 values
	// of the aforementioned types and feed them to Person constructor.
	template<>
	struct MArgumentManager::CustomType<Person> { using CorrespondingTypes = std::tuple<std::string, uint8_t, double>; };

	// Teach LLU how to send Person object as result of the library function. DataStore is used as the actual MArgument type.
	template<>
	void MArgumentManager::set<Person>(const Person& arg) {
		DataList<LLU::NodeType::Any> personDS;
		personDS.push_back(arg.name);
		personDS.push_back(static_cast<mint>(arg.age));
		personDS.push_back(arg.height);
		set(personDS);
	}
}	 // namespace LLU

LLU_LIBRARY_FUNCTION(DescribePerson2) {
	auto person = mngr.get<Person>(0);
	mngr.set(person.description());
}

LLU_LIBRARY_FUNCTION(ComparePeople) {
	using namespace std::string_literals;
	auto personA = mngr.get<Person>(0);
	auto personB = mngr.get<Person>(3);
	mngr.set(personA.name + " is" + (personA.height > personB.height? ""s : " not"s) + " taller than " + personB.name + ".");
}

LLU_LIBRARY_FUNCTION(PredictChild) {
	auto [personA, personB] = mngr.getTuple<Person, Person>();
	mngr.set(Person {personA.name + " Junior", 0, (personA.height + personB.height) / 2});
}

// Fun with vectors - partial end explicit specializations of MArgumentManager::Getter (undocumented feature)
namespace LLU {
	template<typename T>
	struct MArgumentManager::CustomType<std::vector<T>> { using CorrespondingTypes = std::tuple<NumericArray<T>>; };

	template<typename T>
	struct MArgumentManager::Getter<std::vector<T>> {
		static std::vector<T> get(const MArgumentManager& mngr, size_type index) {
			auto na = mngr.get<Managed<NumericArray<T>, LLU::Passing::Constant>>(index);
			return { std::cbegin(na), std::cend(na) };
		}
	};

	template<>
	struct MArgumentManager::CustomType<std::vector<Person>> { using CorrespondingTypes = std::tuple<DataList<LLU::NodeType::Any>>; };

	template<>
	struct MArgumentManager::Getter<std::vector<Person>> {
		static std::vector<Person> get(const MArgumentManager& mngr, size_type index) {
			auto dl = mngr.get<DataList<LLU::NodeType::DataStore>>(index);
			std::vector<Person> res;
			std::transform(dl.valueBegin(), dl.valueEnd(), std::back_inserter(res), [](LLU::GenericDataList ds) {
				NodeValueIterator<LLU::NodeType::Any> it {ds.begin()};
				std::string name { (it++).as<LLU::NodeType::UTF8String>() };
				auto age = static_cast<uint8_t>((it++).as<mint>());
				auto height = (it++).as<double>() ;
				return Person { std::move(name), age, height };
			});
			return res;
		}
	};

	template<typename T>
	struct MArgumentManager::Setter<std::vector<T>> {
		static void set(MArgumentManager& mngr, const std::vector<T>& v) {
			mngr.set(NumericArray<T>{ std::cbegin(v), std::cend(v) });
		}
	};
}	 // namespace LLU

LLU_LIBRARY_FUNCTION(GetTallest) {
	auto people = mngr.get<std::vector<Person>>(0); // non-empty collection of Persons
	auto tallest = std::max_element(cbegin(people), cend(people), [](const Person& p1, const Person& p2) {
		return p1.height < p2.height;
	});
	mngr.set(tallest->name);
}

LLU_LIBRARY_FUNCTION(Sort) {
	auto [v32, v64] = mngr.getTuple<std::vector<int32_t>, std::vector<int64_t>>();
	std::sort(begin(v32), end(v32), std::less<>());
	std::sort(begin(v64), end(v64), std::greater<>());
	std::copy(begin(v32), end(v32), std::back_inserter(v64));
	mngr.set(v64);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Experimental functionality for automatic generation of library functions from regular functions.
/// Not mature enough to be included in LLU, but paclets may copy and use this code (with caution).
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

template<typename R, typename... Args>
void runAsLibraryFunction(LLU::MArgumentManager& mngr, std::function<R(Args...)> f) {
	mngr.set(std::apply(std::move(f), mngr.getTuple<Args...>()));
}

template<typename R, typename... Args>
void runAsLibraryFunction(LLU::MArgumentManager& mngr, R(*f)(Args...)) {
	if constexpr (std::is_same_v<R, void>) {
		std::apply(f, mngr.getTuple<std::decay_t<Args>...>());
	} else {
		mngr.set(std::apply(f, mngr.getTuple<std::decay_t<Args>...>()));
	}
}

template<class C, typename R, typename... Args>
void runAsLibraryFunction(LLU::MArgumentManager& mngr, R(C::*f)(Args...) const) {
	if constexpr (std::is_same_v<R, void>) {
		std::apply(f, mngr.getTuple<C, std::decay_t<Args>...>());
	} else {
		mngr.set(std::apply(f, mngr.getTuple<C, std::decay_t<Args>...>()));
	}
}

#define LIBRARIFY(function) LIBRARIFY_TO(function, LL_##function)

#define LIBRARIFY_TO(function, topLevelName)      \
	LLU_LIBRARY_FUNCTION(topLevelName) {          \
		try {                                     \
			runAsLibraryFunction(mngr, function); \
		} catch (const std::exception& e) {        \
			std::cout << e.what() << std::endl;   \
		}                                         \
	}

std::string repeatString(const std::string& s, unsigned int n) {
	std::string res;
	while (n --> 0) {
		res += s;
	}
	return res;
}
LIBRARIFY(repeatString)

void doNothing() noexcept {}
LIBRARIFY(doNothing)

LIBRARIFY_TO(&Person::description, GetPersonDescription)