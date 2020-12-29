/**
 * @file	ManagedExprTest.cpp
 * @brief
 */
#include <functional>

#include <LLU/ErrorLog/Logger.h>
#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/ManagedExpression.hpp>

/**
 * Sample class to be "managed" by WL.
 * The only requirement is for the class to have a public constructor.
 */
class MyExpression {
public:
	MyExpression(mint myID, std::string text) : id {myID}, text {std::move(text)} {
		LLU_DEBUG("MyExpression[", id, "] created.");
	}

	MyExpression(const MyExpression&) = delete;
	MyExpression& operator=(const MyExpression&) = delete;
	MyExpression(MyExpression&&) = default;
	MyExpression& operator=(MyExpression&&) = default;

	virtual ~MyExpression() {
		LLU_DEBUG("MyExpression[", id, "] is dying now.");
	}

	const std::string& getText() const {
		return text;
	}

	mint getID() const noexcept {
		return id;
	}

	virtual void setText(std::string newText) {
		text = std::move(newText);
	}

private:
	mint id;
	std::string text;
};

DEFINE_MANAGED_STORE_AND_SPECIALIZATION(MyExpression)

// Forward declare an abstract class and define its Store. The class is defined below.
struct Serializable;
LLU::ManagedExpressionStore<Serializable> SerializableStore;

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	MyExpressionStore.registerType("MyExpression");
	SerializableStore.registerType("Serializable");
	return 0;
}

EXTERN_C DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData) {
	MyExpressionStore.unregisterType(libData);
	SerializableStore.unregisterType(libData);
}

LLU_LIBRARY_FUNCTION(GetManagedExpressionCount) {
	mngr.set(static_cast<mint>(MyExpressionStore.size()));
}

LLU_LIBRARY_FUNCTION(GetManagedExpressionTexts) {
	LLU::DataList<std::string_view> texts;
	for (const auto& expr : MyExpressionStore) {
		texts.push_back(std::to_string(expr.first), expr.second->getText());
	}
	mngr.set(texts);
}

LIBRARY_LINK_FUNCTION(OpenManagedMyExpression) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		auto id = mngr.getInteger<mint>(0);
		auto text = mngr.getString(1);
		MyExpressionStore.createInstance(id, id, text);
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

LLU_LIBRARY_FUNCTION(ReleaseExpression) {
	auto id = mngr.getInteger<mint>(0);
	mngr.set(static_cast<mint>(MyExpressionStore.releaseInstance(id)));
}

LIBRARY_LINK_FUNCTION(GetText) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		const MyExpression& myExpr = mngr.getManagedExpression(0, MyExpressionStore);
		mngr.set(myExpr.getText());
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

LIBRARY_LINK_FUNCTION(SetText) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		auto& myExpr = mngr.getManagedExpression(0, MyExpressionStore);
		auto newText = mngr.getString(1);
		myExpr.setText(newText);
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

LIBRARY_LINK_FUNCTION(JoinText) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		const auto& myExpr1 = mngr.getManagedExpression(0, MyExpressionStore);
		const auto& myExpr2 = mngr.getManagedExpression(1, MyExpressionStore);
		mngr.set(myExpr1.getText() + myExpr2.getText());
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

LIBRARY_LINK_FUNCTION(GetMyExpressionStoreName) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		mngr.set(MyExpressionStore.getExpressionName());
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

/**
 * Read managed MyExpression via WSTP to a shared pointer.
 */
template<LLU::WS::Encoding EIn, LLU::WS::Encoding EOut>
LLU::WSStream<EIn, EOut>& operator>>(LLU::WSStream<EIn, EOut>& ws, std::shared_ptr<MyExpression>& myExp) {
	ws >> LLU::WS::Function("MyExpression", 1);
	mint myExprID {};
	ws >> myExprID;
	myExp = MyExpressionStore.getInstancePointer(myExprID);
	return ws;
}

/**
 * Get a reference to a managed MyExpression passed via WSTP
 */
template<LLU::WS::Encoding EIn, LLU::WS::Encoding EOut>
MyExpression& getFromWSTP(LLU::WSStream<EIn, EOut>& ws) {
	ws >> LLU::WS::Function("MyExpression", 1);	   // Watch out for context here!
	mint myExprID {};							   // In paclets the function head will usually be XXXTools`Private`MyExpression
	ws >> myExprID;
	return MyExpressionStore.getInstance(myExprID);
}

/// Get two managed MyExpressions via WSTP and swap texts in them
LIBRARY_WSTP_FUNCTION(SwapText) {
	namespace WS = LLU::WS;
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::WSStream<WS::Encoding::UTF8> ws(wsl, 2);
		std::shared_ptr<MyExpression> firstExpr;
		ws >> firstExpr;
		auto& secondExpr = getFromWSTP(ws);
		auto tempText = firstExpr->getText();
		firstExpr->setText(secondExpr.getText());
		secondExpr.setText(std::move(tempText));
		ws << WS::Null << WS::EndPacket;
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

LIBRARY_WSTP_FUNCTION(SetTextWS) {
	namespace WS = LLU::WS;
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::WSStream<WS::Encoding::UTF8> ws(wsl, 2);
		auto& myExpr = getFromWSTP(ws);
		std::string newText;
		ws >> newText;
		myExpr.setText(std::move(newText));
		ws << WS::Null << WS::EndPacket;
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

// Create a subclass of MyExpression and use it as Managed Expression with the same Store
// All previously defined Get/Set functions should work on MLEs that are actually MyChildExpressions

class MyChildExpression : public MyExpression {
public:
	MyChildExpression(mint myID, std::string text) : MyExpression(myID, childTextPrefix + std::move(text)) {
		LLU_DEBUG("MyChildExpression[", getID(), "] created.");
	}

	MyChildExpression(const MyChildExpression&) = delete;
	MyChildExpression& operator=(const MyChildExpression&) = delete;
	MyChildExpression(MyChildExpression&&) = default;
	MyChildExpression& operator=(MyChildExpression&&) = default;

	~MyChildExpression() override {
		LLU_DEBUG("MyChildExpression[", getID(), "] is dying now.");
	}

	mint getCounter() {
		return ++counter;
	}

	void setText(std::string newText) override {
		MyExpression::setText(childTextPrefix + std::move(newText));
	}

private:
	inline static const std::string childTextPrefix {"I'm a subclass! Here is your text: "};
	mint counter = 0;
};

LIBRARY_LINK_FUNCTION(OpenManagedMyChildExpression) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		auto id = mngr.getInteger<mint>(0);
		auto text = mngr.getString(1);
		MyExpressionStore.createInstance<MyChildExpression>(id, id, text);
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

LIBRARY_LINK_FUNCTION(GetCounter) {
	auto err = LLU::ErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		MyChildExpression& myExpr = mngr.getManagedExpression<MyExpression, MyChildExpression>(0, MyExpressionStore);
		mngr.set(myExpr.getCounter());
	} catch (const LLU::LibraryLinkError& e) {
		err = e.which();
	}
	return err;
}

// Define a hierarchy of classes with an "abstract" base class which would be the Managed one
struct Serializable {
	Serializable() = default;
	Serializable(const Serializable&) = default;
	Serializable(Serializable&&) = default;
	Serializable& operator=(const Serializable&) = default;
	Serializable& operator=(Serializable&&) noexcept = default;
	virtual ~Serializable() = default;

	virtual std::string to_string() = 0;
};

struct A : Serializable {
	std::string to_string() override { return "Hello! I'm A."; }
};

struct B : Serializable {
	explicit B(mint m) : m {m} {}
	std::string to_string() override { return "Hello! I'm B. I hold " + std::to_string(m) + "."; }
private:
	mint m;
};

template<>
inline void LLU::manageInstanceCallback<Serializable>(WolframLibraryData /*unused*/, mbool mode, mint id) {
	SerializableStore.manageInstance(mode, id);
}

// A factory function that returns either A or B object (depending on the argument) via a pointer to abstract base class
std::unique_ptr<Serializable> getSerializable(std::string_view s) {
	if (s.find_first_of("aA") != std::string_view::npos) {
		return std::make_unique<A>();
	}
	auto pos = s.find_last_of("bB");
	if (pos == std::string_view::npos) {
		LLU::ErrorManager::throwException(LLU::ErrorName::FunctionError);
	}
	return std::make_unique<B>(pos);
}

LLU_LIBRARY_FUNCTION(CreateSerializableExpression) {
	auto [id, text] = mngr.getTuple<mint, std::string>();
	SerializableStore.createInstance(id, getSerializable(text));
}

LLU_LIBRARY_FUNCTION(Serialize) {
	auto& myExpr = mngr.getManagedExpression(0, SerializableStore);
	mngr.set(myExpr.to_string());
}