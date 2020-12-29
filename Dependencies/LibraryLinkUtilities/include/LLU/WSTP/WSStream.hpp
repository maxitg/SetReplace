/**
 * @file	WSStream.hpp
 * @date	Nov 23, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Header file for WSStream class.
 */
#ifndef LLU_WSTP_WSSTREAM_HPP_
#define LLU_WSTP_WSSTREAM_HPP_

#include <algorithm>
#include <iterator>
#include <map>
#include <stack>
#include <type_traits>
#include <utility>
#include <vector>

#include "wstp.h"

#include "LLU/ErrorLog/Errors.h"
#include "LLU/Utilities.hpp"

#include "LLU/WSTP/Get.h"
#include "LLU/WSTP/Put.h"
#include "LLU/WSTP/Strings.h"
#include "LLU/WSTP/Utilities.h"
#include "LLU/WSTP/UtilityTypeTraits.hpp"

namespace LLU {

	/**
	 * @class 	WSStream
	 * @brief 	Wrapper class over WSTP with a stream-like interface.
	 *
	 * WSStream resides in LLU namespace, whereas other WSTP-related classes can be found in LLU::WS namespace.
	 *
	 * @tparam	EncodingIn - default encoding to use when reading strings from WSTP
	 * @tparam	EncodingOut - default encoding to use when writing strings to WSTP
	 */
	template<WS::Encoding EncodingIn, WS::Encoding EncodingOut = EncodingIn>
	class WSStream {
	public:
		/**
		 *   @brief			Constructs new WSStream
		 *   @param[in] 	mlp - low-level object of type WSLINK received from LibraryLink
		 **/
		explicit WSStream(WSLINK mlp);

		/**
		 *   @brief         Constructs new WSStream and checks whether there is a list of \c argc arguments on the LinkObject waiting to be read
		 *   @param[in]     mlp - low-level object of type WSLINK received from LibraryLink
		 *   @param[in] 	argc - expected number of arguments
		 **/
		WSStream(WSLINK mlp, int argc);

		/**
		 *   @brief         Constructs new WSStream and checks whether there is a function with head \c head and \c argc arguments on the LinkObject
		 *   				waiting to be read
		 *   @param[in]     mlp - low-level object of type WSLINK received from LibraryLink\
		 *   @param[in]		head - expected head of expression on the Link
		 *   @param[in] 	argc - expected number of arguments
		 *   @throws 		see WSStream::testHead(const std::string&, int);
		 *
		 *   @note			arguments passed to the library function will almost always be wrapped in a List, so if not sure pass "List" as \c head
		 **/
		WSStream(WSLINK mlp, const std::string& head, int argc);

		/**
		 *   @brief Default destructor
		 **/
		~WSStream() = default;

		/**
		 *   @brief Returns a reference to underlying low-level WSTP handle
		 **/
		WSLINK& get() noexcept {
			return m;
		}

		/**
		 *   @brief			Sends any range as List
		 *   @tparam		InputIterator - type that is an iterator
		 *   @param[in] 	begin - iterator to the first element of the range
		 *	 @param[in] 	end - iterator past the last element of the range
		 *
		 **/
		template<typename Iterator, typename = enable_if_input_iterator<Iterator>>
		void sendRange(Iterator begin, Iterator end);

		/**
		 *   @brief			Sends a range of elements as top-level expression with arbitrary head
		 *   @tparam		InputIterator - type that is an iterator
		 *   @param[in] 	begin - iterator to the first element of the range
		 *	 @param[in] 	end - iterator past the last element of the range
		 *	 @param[in]		head - head of the top-level expression
		 *
		 **/
		template<typename Iterator, typename = enable_if_input_iterator<Iterator>>
		void sendRange(Iterator begin, Iterator end, const std::string& head);

	public:
		/// Type of elements that can be sent via WSTP with no arguments, for example WS::Flush
		using StreamToken = WSStream& (*)(WSStream&);

		/// Type of elements that can be either sent or received via WSTP with no arguments, for example WS::Rule
		using BidirStreamToken = WSStream& (*)(WSStream&, WS::Direction);

		/// Type of data stored on the stack to facilitate sending expressions of a priori unknown length
		using LoopbackData = std::pair<std::string, WSLINK>;

		//
		//	operator<<
		//

		/**
		 *   @brief			Sends a stream token via WSTP
		 *   @param[in] 	f - a stream token, i.e. an element that can be sent via WSTP with no arguments, for example WS::Flush
		 **/
		WSStream& operator<<(StreamToken f);

		/**
		 *   @brief			Sends a bidirectional stream token via WSTP
		 *   @param[in] 	f - an element that can be either sent or received via WSTP with no arguments, for example WS::Rule
		 **/
		WSStream& operator<<(BidirStreamToken f);

		/**
		 *   @brief			Sends a top-level symbol via WSTP
		 *   @param[in] 	s - a symbol
		 *   @see 			WS::Symbol
		 *   @throws 		ErrorName::WSPutSymbolError
		 **/
		WSStream& operator<<(const WS::Symbol& s);

		/**
		 *   @brief			Sends a top-level function via WSTP, function arguments should be sent immediately after
		 *   @param[in] 	f - a function
		 *   @see 			WS::Function
		 *   @throws 		ErrorName::WSPutFunctionError
		 **/
		WSStream& operator<<(const WS::Function& f);

		/**
		 *   @brief			Sends a top-level expression of the form Missing["reason"]
		 *   @param[in] 	f - WS::Missing object with a reason
		 *   @see 			WS::Missing
		 *   @throws 		ErrorName::WSPutFunctionError
		 **/
		WSStream& operator<<(const WS::Missing& f);

		/**
		 * @brief		Starts sending a new expression where the number of arguments is not known a priori
		 * @param[in]	expr - object of class BeginExpr that stores expression head as string
		 */
		WSStream& operator<<(const WS::BeginExpr& expr);

		/**
		 * @brief		Drops current expression that was initiated with BeginExpr
		 * @param[in]	expr - object of class DropExpr
		 **/
		WSStream& operator<<(const WS::DropExpr& expr);

		/**
		 * @brief		Ends current expression that was initiated with BeginExpr, prepends the head from BeginExpr and sends everything to the "parent" link
		 * @param[in]	expr - object of class EndExpr
		 **/
		WSStream& operator<<(const WS::EndExpr& expr);

		/**
		 *   @brief			Sends a boolean value via WSTP, it is translated to True or False in Mathematica
		 *   @param[in] 	b - a boolean value
		 *
		 *   @throws 		ErrorName::WSPutSymbolError
		 **/
		WSStream& operator<<(bool b);

		/**
		 *   @brief			Sends a mint value.
		 *   @param[in] 	i - a mint value
		 *
		 *   @throws		ErrorName::WSPutScalarError
		 **/
		WSStream& operator<<(mint i);

		/**
		 *   @brief			Sends a WSTP array
		 *   @tparam		T - array element type
		 *   @param[in] 	a - ArrayData to be sent
		 *   @see 			WS::ArrayData<T>
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingMultidimensionalArrays.html
		 *   @throws 		ErrorName::WSPutArrayError
		 **/
		template<typename T>
		WSStream& operator<<(const WS::ArrayData<T>& a);

		/**
		 *   @brief			Sends a WSTP list
		 *   @tparam		T - list element type
		 *   @param[in] 	l - ListData to be sent
		 *   @see 			WS::ListData<T>
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingLists.html
		 *   @throws 		ErrorName::WSPutListError
		 **/
		template<typename T>
		WSStream& operator<<(const WS::ListData<T>& l);

		/**
		 *   @brief			Sends an object owned by unique pointer
		 *   @tparam		T - list element type
		 *   @tparam		D - destructor type, not really relevant
		 *   @param[in] 	p - pointer to the object to be sent
		 **/
		template<typename T, typename D>
		WSStream& operator<<(const std::unique_ptr<T, D>& p);

		/**
		 *   @brief			Sends a std::vector via WSTP, it is interpreted as a List in Mathematica
		 *   @tparam		T - vector element type (types supported in WSPut*List will be handled more efficiently)
		 *   @param[in] 	l - std::vector to be sent
		 *
		 *   @throws 		ErrorName::WSPutListError
		 **/
		template<typename T>
		WSStream& operator<<(const std::vector<T>& l);

		/**
		 *   @brief			Sends a WSTP string
		 *   @tparam		E - encoding of the string (it determines which function from WSPut*String family to use)
		 *   @param[in] 	s - WS::StringData to be sent
		 *   @see 			WS::StringData<E>
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingStrings.html
		 *   @throws 		ErrorName::WSPutStringError
		 **/
		template<WS::Encoding E>
		WSStream& operator<<(const WS::StringData<E>& s);

		/**
		 *   @brief			Sends all strings within a given object using specified character encoding.
		 *
		 *   Normally, when you send a string WSStream chooses the appropriate WSTP function based on the EncodingOut template parameter.
		 *   Sometimes you may want to locally override the output encoding and you can do this by wrapping the object with
		 *   WS::PutAs<desired encoding, wrapped type> (you can use WS::putAs function to construct WS::PutAs object without
		 *   having to explicitly specify the second template parameter).
		 *
		 *   @code
		 *   	WSStream<WS::Encoding::UTF8> mls { mlink }; 		// By default use UTF8
		 *		std::vector<std::string> vecOfExpr = ....;  		// This is a vector of serialized Mathematica expressions,
		 *		ml << WS::putAs<WS::Encoding::Native>(vecOfExpr); 	// it should be sent with Native encoding
		 *   @endcode
		 *
		 *   @param[in] 	wrp - object to be sent
		 *
		 **/
		template<WS::Encoding E, typename T>
		WSStream& operator<<(const WS::PutAs<E, T>& wrp);

		/**
		 *   @brief			Sends std::basic_string
		 *   @tparam		T - string character type supported in any of WSPut*String
		 *   @param[in] 	s - std::basic_string<T> to be sent
		 *
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingStrings.html
		 *   @throws 		ErrorName::WSPutStringError
		 *
		 **/
		template<typename T>
		WSStream& operator<<(const std::basic_string<T>& s);

		/**
		 *   @brief			Sends a character array (or a string literal)
		 *   @tparam		T - character type supported in any of WSPut*String
		 *   @tparam		N - length of character array
		 *   @param[in] 	s - character array to be sent as String
		 *
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingStrings.html
		 *   @throws 		ErrorName::WSPutStringError
		 **/
		template<typename T, std::size_t N, typename = std::enable_if_t<WS::StringTypeQ<T>>>
		WSStream& operator<<(const T (&s)[N]);

		/**
		 *   @brief			Sends a C-string
		 *   @param[in] 	s - C-string to be sent
		 *
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingStrings.html
		 *   @throws 		ErrorName::WSPutStringError
		 **/
		WSStream& operator<<(const char* s);

		/**
		 *   @brief			Sends a std::map via WSTP, it is translated to an Association in Mathematica
		 *   @tparam		K - map key type, must be supported in WSStream
		 *   @tparam		V - map value type, must be supported in WSStream
		 *   @param[in] 	map - map to be sent as Association
		 *
		 *   @throws 		ErrorName::WSPutFunctionError plus whatever can be thrown sending keys and values
		 **/
		template<typename K, typename V>
		WSStream& operator<<(const std::map<K, V>& map);

		/**
		 *   @brief			Sends a scalar value (int, float, double, etc) if it is supported by WSTP
		 *   If you need to send value of type not supported by WSTP (like unsigned int) you must either explicitly cast
		 *   or provide your own overload.
		 *   @tparam		T - scalar type
		 *   @param[in] 	value - numeric value to be sent
		 *
		 *   @throws 		ErrorName::WSPutScalarError
		 **/
		template<typename T, typename = std::enable_if_t<std::is_arithmetic_v<T>>>
		WSStream& operator<<(T value);

		/**
		 *   @brief			Sends any container (a class with begin(), end() and size()) as List
		 *   @tparam		Container - type that is a collection of some elements
		 *   @param[in] 	c - container to be sent
		 *
		 *   @throws 		ErrorName::WSPutContainerError
		 *
		 *   @note			Size() is not technically necessary, but needed for performance reason. Most STL containers have size() anyway.
		 **/
		template<typename Container, typename = std::void_t<
										 decltype(std::declval<Container>().begin(), std::declval<Container>().end(), std::declval<Container>().size())>>
		WSStream& operator<<(const Container& c) {
			sendRange(c.begin(), c.end());
			return *this;
		}

		//
		//	operator>>
		//

		/**
		 *   @brief			Receives a bidirectional stream token via WSTP
		 *   @param[in] 	f - an element that can be either sent or received via WSTP with no arguments, for example WS::Rule
		 **/
		WSStream& operator>>(BidirStreamToken f);

		/**
		 *   @brief			Receives a symbol from WSTP.
		 *
		 *   Parameter \c s must have head specified and it has to match the head that was read from WSTP
		 *
		 *   @param[in] 	s - a symbol
		 *   @see 			WS::Symbol
		 *   @throws 		ErrorName::WSGetSymbolError, ErrorName::WSTestHeadError
		 **/
		WSStream& operator>>(const WS::Symbol& s);

		/**
		 *   @brief				Receives a symbol from WSTP.
		 *
		 *   If the parameter \c s has head specified, then it has to match the head that was read from WSTP, otherwise the head read from WSTP
		 *   will be assigned to s
		 *
		 *   @param[in, out] 	s - a symbol
		 *   @see 				WS::Symbol
		 *   @throws 			ErrorName::WSGetSymbolError, ErrorName::WSTestHeadError
		 **/
		WSStream& operator>>(WS::Symbol& s);

		/**
		 *   @brief			Receives a function from WSTP.
		 *
		 *   Parameter \c f must have head and argument count specified and they need to match the head and argument count that was read from WSTP
		 *
		 *   @param[in] 	f - a function with head and argument count specified
		 *   @see 			WS::Function
		 *   @throws 		ErrorName::WSGetFunctionError, ErrorName::WSTestHeadError
		 **/
		WSStream& operator>>(const WS::Function& f);

		/**
		 *   @brief				Receives a function from WSTP.
		 *
		 *   If the parameter \c f has head or argument count set, than it has to match the head or argument count that was read from WSTP
		 *
		 *   @param[in, out] 	f - a function which may have head or argument count specified
		 *   @see 				WS::Function
		 *   @throws 			ErrorName::WSGetFunctionError, ErrorName::WSTestHeadError
		 **/
		WSStream& operator>>(WS::Function& f);

		/**
		 *   @brief			Receives a True or False symbol from Mathematica and converts it to bool
		 *   @param[out] 	b - argument to which the boolean received from WSTP will be assigned
		 *
		 *   @throws 		ErrorName::WSGetSymbolError, ErrorName::WSWrongSymbolForBool
		 **/
		WSStream& operator>>(bool& b);

		/**
		 *   @brief			Receives a mint value.
		 *   @param[in] 	i - argument to which a mint value will be assigned
		 *
		 *   @note		    It actually reads an wsint64 and casts to mint, as mint is not natively supported by WSTP.
		 **/
		WSStream& operator>>(mint& i);

		/**
		 *   @brief			Receives a WSTP array
		 *   @tparam		T - array element type
		 *   @param[out] 	a - argument to which the WS::ArrayData received from WSTP will be assigned
		 *   @see 			WS::ArrayData<T>
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingMultidimensionalArrays.html
		 *   @throws 		ErrorName::WSGetArrayError
		 **/
		template<typename T>
		WSStream& operator>>(WS::ArrayData<T>& a);

		/**
		 *   @brief			Receives a WSTP list
		 *   @tparam		T - list element type
		 *   @param[out] 	l - argument to which the WS::ListData received from WSTP will be assigned
		 *   @see 			WS::ListData<T>
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingLists.html
		 *   @throws 		ErrorName::WSGetListError
		 **/
		template<typename T>
		WSStream& operator>>(WS::ListData<T>& l);

		/**
		 *   @brief			Receives a List from WSTP and assigns it to std::vector
		 *   @tparam		T - vector element type (types supported in WSGet*List will be handled more efficiently)
		 *   @param[out] 	l - argument to which the List received from WSTP will be assigned
		 *
		 *   @throws 		ErrorName::WSGetListError
		 **/
		template<typename T>
		WSStream& operator>>(std::vector<T>& l);

		/**
		 *   @brief			Receives a WSTP string
		 *   @tparam		T - string character type
		 *   @param[out] 	s - argument to which the WS::StringData received from WSTP will be assigned
		 *   @see 			WS::StringData<T>
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingStrings.html
		 *   @throws 		ErrorName::WSGetStringError
		 **/
		template<WS::Encoding E = EncodingIn>
		WSStream& operator>>(WS::StringData<E>& s);

		/**
		 *   @brief			Receives std::basic_string
		 *   @tparam		T - string character type supported in any of WSGet*String
		 *   @param[out] 	s - argument to which the std::basic_string<T> received from WSTP will be assigned
		 *
		 *   @see			http://reference.wolfram.com/language/guide/WSTPCFunctionsForExchangingStrings.html
		 *   @throws 		ErrorName::WSGetStringError
		 *
		 *   @note			std::string is just std::basic_string<char>
		 **/
		template<typename T>
		WSStream& operator>>(std::basic_string<T>& s);

		/**
		 *	 @brief			Receives a value of type T
		 *	 @tparam		E - encoding to be used when reading value from WSTP
		 *	 @tparam		T - value type
		 *	 @param 		wrp - reference to object of type T wrapped in WS::GetAs structure
		 *
		 * 	 @note			There is a utility function WS::getAs for easier creation of WS::GetAs objects
		 */
		template<WS::Encoding E, typename T>
		WSStream& operator>>(WS::GetAs<E, T> wrp);

		/**
		 *   @brief			Receives a std::map via WSTP
		 *   @tparam		K - map key type, must be supported in WSStream
		 *   @tparam		V - map value type, must be supported in WSStream
		 *   @param[out] 	map - argument to which the std::map received from WSTP will be assigned
		 *
		 *   @throws 		ErrorName::WSGetFunctionError plus whatever can be thrown receiving keys and values
		 *
		 *   @note			The top-level Association must have all values of the same type because this is how std::map works
		 **/
		template<typename K, typename V>
		WSStream& operator>>(std::map<K, V>& map);

		/**
		 *   @brief			Receives a scalar value (int, float, double, etc) if it is supported by WSTP
		 *   If you need to receive value of type not supported by WSTP (like unsigned int) you must either explicitly cast
		 *   or provide your own overload.
		 *   @tparam		T - scalar type
		 *   @param[out] 	value - argument to which the value received from WSTP will be assigned
		 *
		 *   @throws 		ErrorName::WSGetScalarError
		 **/
		template<typename T, typename = std::enable_if_t<std::is_arithmetic_v<T>>>
		WSStream& operator>>(T& value);

	private:
		/**
		 *   @brief			Check if the call to WSTP API succeeded, throw an exception otherwise
		 *   @param[in] 	statusOk - error code returned from WSTP API function, usually 0 means error
		 *   @param[in]		errorName - which exception to throw
		 *   @param[in]		debugInfo - additional information to include in the exception, should it be thrown
		 *
		 *   @throws 		errorName
		 **/
		void check(int statusOk, const std::string& errorName, const std::string& debugInfo = "");

		/**
		 * 	 @brief			Test if the next expression to be read from WSTP has given head
		 * 	 @param[in] 	head - expression head to test for
		 * 	 @return		Number of arguments for the next expression on the Link (only if head is correct)
		 *
		 * 	 @throws		ErrorName::WSTestHeadError
		 */
		int testHead(const std::string& head);

		/**
		 * 	 @brief			Test if the next expression to be read from WSTP has given head and given number of arguments
		 * 	 @param[in] 	head - expression head to test for
		 * 	 @param[in]		argc - number of arguments to test for
		 *
		 * 	 @throws		ErrorName::WSTestHeadError
		 */
		void testHead(const std::string& head, int argc);

		/**
		 *	@brief	Update the value of m to point to the top of loopbackStack.
		 */
		void refreshCurrentWSLINK();

	private:
		/// Internal low-level handle to the currently active WSTP, it is assumed that the handle is valid.
		WSLINK m {};

		/// WSTP does not natively support sending expression of unknown length, so to simulate this behavior we can use a helper loopback link to store
		/// arguments until we know how many of them there are. But to be able to send nested expressions of unknown length we need more than one helper link.
		/// The data structure called stack seems to be the most reasonable choice.
		std::stack<LoopbackData> loopbackStack;

		/// Boolean flag to indicate if the current expression initiated with BeginExpr has been dropped. It is needed for EndExpr to behave correctly.
		bool currentExprDropped = false;
	};

/// @cond

	template<WS::Encoding EIn, WS::Encoding EOut>
	WSStream<EIn, EOut>::WSStream(WSLINK mlp) : m(mlp), loopbackStack(std::deque<LoopbackData> {{"", mlp}}) {
		if (!mlp) {
			WS::Detail::throwLLUException(ErrorName::WSNullWSLinkError);
		}
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	WSStream<EIn, EOut>::WSStream(WSLINK mlp, int argc) : WSStream(mlp, "List", argc) {}

	template<WS::Encoding EIn, WS::Encoding EOut>
	WSStream<EIn, EOut>::WSStream(WSLINK mlp, const std::string& head, int argc) : WSStream(mlp) {
		testHead(head, argc);
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename Iterator, typename>
	void WSStream<EIn, EOut>::sendRange(Iterator begin, Iterator end) {
		sendRange(begin, end, "List");
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename Iterator, typename>
	void WSStream<EIn, EOut>::sendRange(Iterator begin, Iterator end, const std::string& head) {
		*this << WS::Function(head, static_cast<int>(std::distance(begin, end)));
		std::for_each(begin, end, [this](const auto& elem) { *this << elem; });
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	void WSStream<EIn, EOut>::check(int statusOk, const std::string& errorName, const std::string& debugInfo) {
		WS::Detail::checkError(m, statusOk, errorName, debugInfo);
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	int WSStream<EIn, EOut>::testHead(const std::string& head) {
		int argcount {};
		check(WSTestHead(m, head.c_str(), &argcount), ErrorName::WSTestHeadError, "Expected \"" + head + "\"");
		return argcount;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	void WSStream<EIn, EOut>::testHead(const std::string& head, int argc) {
		int argcount = testHead(head);
		if (argc != argcount) {
			WS::Detail::throwLLUException(ErrorName::WSTestHeadError, "Expected " + std::to_string(argc) + " arguments but got " + std::to_string(argcount));
		}
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	void WSStream<EIn, EOut>::refreshCurrentWSLINK() {
		if (loopbackStack.empty()) {
			WS::Detail::throwLLUException(ErrorName::WSLoopbackStackSizeError, "Stack is empty in refreshCurrentWSLINK()");
		}
		m = std::get<WSLINK>(loopbackStack.top());
	}

	//
	//	Definitions of WSStream<EIn, EOut>::operator<<
	//

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(StreamToken f) -> WSStream& {
		return f(*this);
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(BidirStreamToken f) -> WSStream& {
		return f(*this, WS::Direction::Put);
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(const WS::Symbol& s) -> WSStream& {
		check(WSPutSymbol(m, s.getHead().c_str()), ErrorName::WSPutSymbolError, "Cannot put symbol: \"" + s.getHead() + "\"");
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(const WS::Function& f) -> WSStream& {
		check(WSPutFunction(m, f.getHead().c_str(), f.getArgc()), ErrorName::WSPutFunctionError,
			  "Cannot put function: \"" + f.getHead() + "\" with " + std::to_string(f.getArgc()) + " arguments");
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(const WS::Missing& f) -> WSStream& {
		check(WSPutFunction(m, f.getHead().c_str(), 1),	   // f.getArgc() could be 0 but we still want to send f.reason, even if it's an empty string
			  ErrorName::WSPutFunctionError, "Cannot put function: \"" + f.getHead() + "\" with 1 argument");
		*this << f.why();
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(const WS::BeginExpr& expr) -> WSStream& {

		// reset dropped expression flag
		currentExprDropped = false;

		// create a new LoopbackLink for the expression
		auto* loopback = WS::Detail::getNewLoopback(m);

		// store expression head together with the link on the stack
		loopbackStack.emplace(expr.getHead(), loopback);

		// active WSLINK changes
		refreshCurrentWSLINK();

		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(const WS::DropExpr& /*tag*/) -> WSStream& {
		// check if the stack has reasonable size
		if (loopbackStack.size() < 2) {
			WS::Detail::throwLLUException(ErrorName::WSLoopbackStackSizeError,
								  "Trying to Drop expression with loopback stack size " + std::to_string(loopbackStack.size()));
		}
		// we are dropping the expression so just close the link and hope that WSTP will do the cleanup
		WSClose(std::get<WSLINK>(loopbackStack.top()));
		loopbackStack.pop();
		refreshCurrentWSLINK();

		// set the dropped expression flag
		currentExprDropped = true;

		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(const WS::EndExpr& /*tag*/) -> WSStream& {

		// if the expression has been dropped at some point, then just reset the flag and do nothing as the loopback link no longer exists
		if (currentExprDropped) {
			currentExprDropped = false;
			return *this;
		}

		// check if the stack has reasonable size
		if (loopbackStack.size() < 2) {
			WS::Detail::throwLLUException(ErrorName::WSLoopbackStackSizeError,
								  "Trying to End expression with loopback stack size " + std::to_string(loopbackStack.size()));
		}

		// extract active loopback link and expression head
		auto currentPartialExpr = loopbackStack.top();
		loopbackStack.pop();

		// active WSLINK changes
		refreshCurrentWSLINK();

		// now count the expressions accumulated in the loopback link and send them to the parent link after the head
		auto& exprArgs = std::get<WSLINK>(currentPartialExpr);
		auto argCnt = WS::Detail::countExpressionsInLoopbackLink(exprArgs);
		*this << WS::Function(std::get<std::string>(currentPartialExpr), argCnt);
		check(WSTransferToEndOfLoopbackLink(m, exprArgs), ErrorName::WSTransferToLoopbackError,
			  "Could not transfer " + std::to_string(argCnt) + " expressions from Loopback Link");
		// finally, close the loopback link
		WSClose(exprArgs);

		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(bool b) -> WSStream& {
		return *this << WS::Symbol(b ? "True" : "False");
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(mint i) -> WSStream& {
		WS::PutScalar<wsint64>::put(m, static_cast<wsint64>(i));
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator<<(const WS::ArrayData<T>& a) -> WSStream& {
		const auto& del = a.get_deleter();
		WS::PutArray<T>::put(m, a.get(), del.getDims(), del.getHeads(), del.getRank());
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator<<(const WS::ListData<T>& l) -> WSStream& {
		const auto& del = l.get_deleter();
		WS::PutList<T>::put(m, l.get(), del.getLength());
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T, typename D>
	auto WSStream<EIn, EOut>::operator<<(const std::unique_ptr<T, D>& p) -> WSStream& {
		if (p) {
			*this << *p;
		} else {
			*this << WS::Null;
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator<<(const std::vector<T>& l) -> WSStream& {
		if constexpr (WS::ScalarSupportedTypeQ<T>) {
			WS::PutList<T>::put(m, l.data(), static_cast<int>(l.size()));
		} else {
			*this << WS::List(static_cast<int>(l.size()));
			for (const auto& elem : l) {
				*this << elem;
			}
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<WS::Encoding E>
	auto WSStream<EIn, EOut>::operator<<(const WS::StringData<E>& s) -> WSStream& {
		WS::String<E>::put(m, s.get(), s.get_deleter().getLength());
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator<<(const std::basic_string<T>& s) -> WSStream& {
		if constexpr (WS::StringTypeQ<T>) {
			WS::String<EOut>::put(m, s.c_str(), static_cast<int>(s.size()));
		} else {
			static_assert(dependent_false_v<T>, "Calling operator<< with unsupported character type.");
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T, std::size_t N, typename>
	auto WSStream<EIn, EOut>::operator<<(const T (&s)[N]) -> WSStream& {
		WS::String<EOut>::put(m, s, N);
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<WS::Encoding E, typename T>
	auto WSStream<EIn, EOut>::operator<<(const WS::PutAs<E, T>& wrp) -> WSStream& {
		WSStream<EIn, E> tmpWSS {m};
		tmpWSS << wrp.obj;
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator<<(const char* s) -> WSStream& {
		WS::String<EOut>::put(m, s, static_cast<int>(std::strlen(s)));
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T, typename>
	auto WSStream<EIn, EOut>::operator<<(T value) -> WSStream& {
		if constexpr (WS::ScalarSupportedTypeQ<T>) {
			WS::PutScalar<T>::put(m, value);
		} else {
			static_assert(dependent_false_v<T>, "Calling operator<< with unsupported scalar type.");
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename K, typename V>
	auto WSStream<EIn, EOut>::operator<<(const std::map<K, V>& map) -> WSStream& {
		*this << WS::Association(static_cast<int>(map.size()));
		for (const auto& elem : map) {
			*this << WS::Rule << elem.first << elem.second;
		}
		return *this;
	}

	//
	//	Definitions of WSStream<EIn, EOut>::operator>>
	//

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator>>(BidirStreamToken f) -> WSStream& {
		return f(*this, WS::Direction::Get);
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator>>(const WS::Symbol& s) -> WSStream& {
		check(WSTestSymbol(m, s.getHead().c_str()), ErrorName::WSTestSymbolError, "Cannot get symbol: \"" + s.getHead() + "\"");
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator>>(WS::Symbol& s) -> WSStream& {
		if (!s.getHead().empty()) {
			check(WSTestSymbol(m, s.getHead().c_str()), ErrorName::WSTestSymbolError, "Cannot get symbol: \"" + s.getHead() + "\"");
		} else {
			const char* head {};
			check(WSGetSymbol(m, &head), ErrorName::WSGetSymbolError, "Cannot get symbol");
			s.setHead(head);
			WSReleaseSymbol(m, head);
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator>>(const WS::Function& f) -> WSStream& {
		testHead(f.getHead(), f.getArgc());
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator>>(WS::Function& f) -> WSStream& {
		if (!f.getHead().empty()) {
			if (f.getArgc() < 0) {
				f.setArgc(testHead(f.getHead()));
			} else {
				testHead(f.getHead(), f.getArgc());
			}
		} else {
			const char* head {};
			int argc {};
			check(WSGetFunction(m, &head, &argc), ErrorName::WSGetFunctionError, "Cannot get function");
			f.setHead(head);
			WSReleaseSymbol(m, head);
			f.setArgc(argc);
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator>>(bool& b) -> WSStream& {
		WS::Symbol boolean;
		*this >> boolean;
		if (boolean.getHead() == "True") {
			b = true;
		} else if (boolean.getHead() == "False") {
			b = false;
		} else {
			WS::Detail::throwLLUException(ErrorName::WSWrongSymbolForBool, R"(Expected "True" or "False", got )" + boolean.getHead());
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	auto WSStream<EIn, EOut>::operator>>(mint& i) -> WSStream& {
		i = static_cast<mint>(WS::GetScalar<wsint64>::get(m));
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<WS::Encoding E, typename T>
	auto WSStream<EIn, EOut>::operator>>(WS::GetAs<E, T> wrp) -> WSStream& {
		WSStream<E, EOut> tmpWSS {m};
		tmpWSS >> wrp.obj;
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator>>(WS::ArrayData<T>& a) -> WSStream& {
		a = WS::GetArray<T>::get(m);
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator>>(WS::ListData<T>& l) -> WSStream& {
		l = WS::GetList<T>::get(m);
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator>>(std::vector<T>& l) -> WSStream& {
		if constexpr (WS::ScalarSupportedTypeQ<T>) {
			auto list = WS::GetList<T>::get(m);
			T* start = list.get();
			auto listLen = list.get_deleter().getLength();
			l = std::vector<T> {start, std::next(start, listLen)};
		} else {
			WS::List inList;
			*this >> inList;
			std::vector<T> res(inList.getArgc());
			for (auto& elem : res) {
				*this >> elem;
			}
			l = std::move(res);
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<WS::Encoding E>
	auto WSStream<EIn, EOut>::operator>>(WS::StringData<E>& s) -> WSStream& {
		s = WS::String<E>::get(m);
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T>
	auto WSStream<EIn, EOut>::operator>>(std::basic_string<T>& s) -> WSStream& {
		if constexpr (WS::StringTypeQ<T>) {
			s = WS::String<EIn>::template getString<T>(m);
		} else {
			static_assert(dependent_false_v<T>, "Calling operator>> with unsupported character type.");
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename K, typename V>
	auto WSStream<EIn, EOut>::operator>>(std::map<K, V>& map) -> WSStream& {
		auto elemCount = testHead("Association");
		for (auto i = 0; i < elemCount; ++i) {
			*this >> WS::Rule;
			K key;
			*this >> key;
			V value;
			*this >> value;
			map.emplace(std::move(key), std::move(value));
		}
		return *this;
	}

	template<WS::Encoding EIn, WS::Encoding EOut>
	template<typename T, typename>
	auto WSStream<EIn, EOut>::operator>>(T& value) -> WSStream& {
		if constexpr (WS::ScalarSupportedTypeQ<T>) {
			value = WS::GetScalar<T>::get(m);
		} else {
			static_assert(dependent_false_v<T>, "Calling operator>> with unsupported type.");
		}
		return *this;
	}
/// @endcond

} /* namespace LLU */

#endif /* LLU_WSTP_WSSTREAM_HPP_ */
