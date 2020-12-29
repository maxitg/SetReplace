/**
 * @file	Utilities.h
 * @date	Nov 26, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Header file with miscellaneous utilities used throughout the WSTP-related part of LibraryLinkUtilities
 */
#ifndef LLU_WSTP_UTILITIES_H_
#define LLU_WSTP_UTILITIES_H_

#include <cstring>
#include <string>

#include "wstp.h"

#include "LLU/ErrorLog/Errors.h"
#include "LLU/WSTP/EncodingTraits.hpp"

namespace LLU {

	template<WS::Encoding, WS::Encoding>
	class WSStream;

	/**
	 * @brief Contains definitions related to WSTP functionality in LLU
	 */
	namespace WS {

		/**
		 * @struct 	Symbol
		 * @brief	Structure representing any symbol in Wolfram Language
		 */
		struct Symbol {
			/**
			 * @brief Default constructor.
			 * The head is empty and such Symbol can be used as argument of WSStream::operator>>, so to read a Symbol from top-level.
			 */
			Symbol() = default;

			/**
			 * @brief	Constructs a Symbol given its head.
			 * @param 	h - head (or Symbol's name)
			 */
			explicit Symbol(std::string h) : head(std::move(h)) {};

			/**
			 * Get Symbol name/head.
			 * @return head
			 */
			const std::string& getHead() const;

			/**
			 * Set Symbol name/head.
			 * @param h - new head for the Symbol
			 */
			void setHead(std::string h);

		private:
			std::string head;
		};

		/**
		 * @struct 	Function
		 * @brief	Structure representing any function in Wolfram Language, i.e. a head plus number of arguments.
		 */
		struct Function : Symbol {

			/**
			 * @brief Default constructor.
			 * The head is empty and number of arguments is set to a dummy value.
			 * This constructor should only be used to create a Function right before calling WSStream::operator>> on it, which will read a function from
			 * top-level.
			 */
			Function() : Function("", -1) {};

			/**
			 * @brief Create a Function with given head but unknown number of arguments.
			 * You can later call WSStream::operator>> on such constructed Function to populate argument count with a value read from top-level.
			 * @param h - function head
			 */
			explicit Function(const std::string& h) : Function(h, -1) {}

			/**
			 * @brief	Construct a Function with given head and number of arguments
			 * @param 	h - function head
			 * @param 	argCount - number of arguments this function takes
			 */
			Function(const std::string& h, int argCount) : Symbol(h), argc(argCount) {}

			/**
			 * @brief	Get argument count.
			 * @return 	number of arguments this function takes
			 */
			int getArgc() const;

			/**
			 * @brief Set argument count.
			 * @param newArgc - new value for argument count
			 */
			void setArgc(int newArgc);

		private:
			int argc;
		};

		/**
		 * Special type of a Function which corresponds to the Association expression when exchanged with the Kernel via WSStream.
		 */
		struct Association : Function {
			/// Default constructor - sets "Association" to be the head of expression with no arguments
			Association() : Function("Association") {}

			/**
			 * Create a WSStream-compatible structure that corresponds to an Association with given number of arguments
			 * @param argCount - number of arguments for the Association expression
			 */
			explicit Association(int argCount) : Function("Association", argCount) {}
		};

		/**
		 * Special type of a Function which corresponds to the List expression when exchanged with the Kernel via WSStream.
		 */
		struct List : Function {
			/// Default constructor - sets "List" to be the head of expression with no arguments
			List() : Function("List") {}

			/**
			 * Create a WSStream-compatible structure that corresponds to a List of given length
			 * @param argCount - number of arguments for the List expression, i.e. length of the list
			 */
			explicit List(int argCount) : Function("List", argCount) {}
		};

		/**
		 * Special type of a Function which corresponds to the Missing expression when exchanged with the Kernel via WSStream.
		 */
		struct Missing : Function {
			/// Default constructor - sets "Missing" to be the head of expression with no arguments
			Missing() : Function("Missing") {}

			/**
			 * Create a WSStream-compatible structure that corresponds to a Missing expression with given "reason"
			 * @param r - reason for the Missing
			 */
			explicit Missing(std::string r) : Function("Missing", 1), reason(std::move(r)) {}

			/**
			 * Get the first argument of the expression which is the reason for the data's being missing
			 * @return the reason, typically "NotApplicable", "Unknown", "NotAvailable", "Nonexistent", etc.
			 * @see https://reference.wolfram.com/language/ref/Missing.html
			 */
			const std::string& why() const {
				return reason;
			}

		private:
			std::string reason;
		};

		namespace Detail {
			/**
			 * @brief 		Checks if WSTP operation was successful and throws appropriate exception otherwise
			 * @param[in] 	m - low-level object of type WSLINK received from LibraryLink
			 * @param[in] 	statusOk - status code return from a WSTP function
			 * @param[in] 	errorName - what error name to put in the exception if WSTP function failed
			 * @param[in] 	debugInfo - additional info to be attached to the exception
			 */
			void checkError(WSLINK m, int statusOk, const std::string& errorName, const std::string& debugInfo = "");

			/**
			 * @brief	Simple wrapper over ErrorManager::throwException used to break dependency cycle between WSStream and ErrorManager.
			 * @param 	errorName - what error name to put in the exception
			 * @param 	debugInfo - additional info to be attached to the exception
			 */
			[[noreturn]] void throwLLUException(const std::string& errorName, const std::string& debugInfo = "");

			/**
			 * @brief	Returns a new loopback link using WSLinkEnvironment(m) as WSENV
			 * @param 	m - valid WSLINK
			 * @return 	a brand new Loopback Link
			 */
			WSLINK getNewLoopback(WSLINK m);

			/**
			 * @brief	Get the number of expressions stored in the loopback link
			 * @param	lpbckLink - a reference to the loopback link, after expressions are counted this argument will be assigned a different WSLINK
			 * @return	a number of expression stored in the loopback link
			 */
			int countExpressionsInLoopbackLink(WSLINK& lpbckLink);
		}	 // namespace Detail

		/// Helper enum for tokens that can be sent via WSTP in both directions, e.g. WS::Null
		enum class Direction : bool { Get, Put };

		/**
		 * NewPacket is a WSStream token which tells WSTP to skip to the end of the current packet
		 * @see     https://reference.wolfram.com/language/ref/c/WSNewPacket.html
		 * @tparam  EIn - WSStream input encoding (will be inferred from the argument)
		 * @tparam  EOut - WSStream output encoding (will be inferred from the argument)
		 * @param   ms - stream object
		 * @return  the stream object
		 */
		template<WS::Encoding EIn, WS::Encoding EOut>
		WSStream<EIn, EOut>& NewPacket(WSStream<EIn, EOut>& ms) {
			Detail::checkError(ms.get(), WSNewPacket(ms.get()), ErrorName::WSPacketHandleError, "Error in WSNewPacket");
			return ms;
		}

		/**
		 * EndPacket is a WSStream token which tells WSTP that the current expression is complete and is ready to be sent
		 * @see     https://reference.wolfram.com/language/ref/c/WSEndPacket.html
		 * @tparam  EIn - WSStream input encoding (will be inferred from the argument)
		 * @tparam  EOut - WSStream output encoding (will be inferred from the argument)
		 * @param   ms - stream object
		 * @return  the stream object
		 */
		template<WS::Encoding EIn, WS::Encoding EOut>
		WSStream<EIn, EOut>& EndPacket(WSStream<EIn, EOut>& ms) {
			Detail::checkError(ms.get(), WSEndPacket(ms.get()), ErrorName::WSPacketHandleError, "Error in WSEndPacket");
			return ms;
		}

		/**
		 * Flush is a WSStream token which tells WSTP to flush out any buffers containing data waiting to be sent on link
		 * @see     https://reference.wolfram.com/language/ref/c/WSFlush.html
		 * @tparam  EIn - WSStream input encoding (will be inferred from the argument)
		 * @tparam  EOut - WSStream output encoding (will be inferred from the argument)
		 * @param   ms - stream object
		 * @return  the stream object
		 */
		template<WS::Encoding EIn, WS::Encoding EOut>
		WSStream<EIn, EOut>& Flush(WSStream<EIn, EOut>& ms) {
			Detail::checkError(ms.get(), WSFlush(ms.get()), ErrorName::WSFlowControlError, "Error in WSFlush");
			return ms;
		}

		/**
		 * Rule is a WSStream token corresponding to a Rule expression in the WolframLanguage
		 * @tparam  EIn - WSStream input encoding (will be inferred from the argument)
		 * @tparam  EOut - WSStream output encoding (will be inferred from the argument)
		 * @param   ms - stream object
		 * @param   dir - stream direction, you don't need to specify this argument when using Rule in a WSStream::operator<< or operator>>
		 * @return  the stream object
		 */
		template<WS::Encoding EIn, WS::Encoding EOut>
		WSStream<EIn, EOut>& Rule(WSStream<EIn, EOut>& ms, Direction dir) {
			if (dir == Direction::Put) {
				return ms << Function("Rule", 2);
			}
			return ms >> Function("Rule", 2);
		}

		/**
		 * Null is a WSStream token corresponding to a Null expression in the WolframLanguage
		 * @tparam  EIn - WSStream input encoding (will be inferred from the argument)
		 * @tparam  EOut - WSStream output encoding (will be inferred from the argument)
		 * @param   ms - stream object
		 * @param   dir - stream direction, you don't need to specify this argument when using Null in a WSStream::operator<< or operator>>
		 * @return  the stream object
		 */
		template<WS::Encoding EIn, WS::Encoding EOut>
		WSStream<EIn, EOut>& Null(WSStream<EIn, EOut>& ms, Direction dir) {
			if (dir == Direction::Put) {
				return ms << Symbol("Null");
			}
			return ms >> Symbol("Null");
		}

		/**
		 * @struct BeginExpr
		 * A token for the WSStream to indicate that we will be sending an expression which length is not known beforehand
		 */
		struct BeginExpr : Symbol {
			/**
			 * Create a token for the WSStream which initiates sending an expression with given head and unknown number of arguments
			 * @param head - head of the expression to be sent
			 */
			explicit BeginExpr(const std::string& head) : Symbol(head) {}
		};

		/**
		 * @struct DropExpr
		 * A token for the WSStream to indicate that current expression started with BeginExpr should be immediately discarded
		 */
		struct DropExpr {};

		/**
		 * @struct EndExpr
		 * A token for the WSStream to indicate that current expression started with BeginExpr has ended and we can forward it to the "parent" link
		 */
		struct EndExpr {};

	}	 // namespace WS
}	 // namespace LLU

#endif /* LLU_WSTP_UTILITIES_H_ */
