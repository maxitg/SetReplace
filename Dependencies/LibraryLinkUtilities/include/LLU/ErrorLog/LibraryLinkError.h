/**
 * @file	LibraryLinkError.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 *
 * @brief	Error class and error codes used by LibraryLink Utilities classes
 *
 */
#ifndef LLU_ERRORLOG_LIBRARYLINKERROR_H_
#define LLU_ERRORLOG_LIBRARYLINKERROR_H_

#include <stdexcept>
#include <string>

#include "LLU/WSTP/WSStream.hpp"

/**
 * @namespace LLU
 * @brief Main namespace of LibraryLink Utilities.
 *
 * Every symbol defined in LLU will be in this namespace, but one needs to remember that LLU internally includes WolframLibrary and WSTP headers which define
 * C APIs and therefore do not use namespaces and in consequence will inject names in the global namespace.
 */
namespace LLU {

	/**
	 * @class	LibraryLinkError
	 * @brief	Class representing an exception in paclet code
	 *
	 * All exceptions that are thrown from paclet code should be of this class. To prevent users from overriding predefined LLU exceptions the constructor
	 * of LibraryLinkError class is private. Developers should use ErrorManager::throwException method to throw exceptions.
	 **/
	class LibraryLinkError : public std::runtime_error {
		friend class ErrorManager;

	public:
		/// A type that holds error id numbers
		using IdType = int;

		/// Copy-constructor. If there are any messages parameters on the WSLINK, a deep copy is performed.
		LibraryLinkError(const LibraryLinkError& e) noexcept;

		/// Copy-assignment operator.
		LibraryLinkError& operator=(const LibraryLinkError& e) noexcept;

		/// Move-constructor. Steals messagesParams from \p e.
		LibraryLinkError(LibraryLinkError&& e) noexcept;

		/// Move-assignment operator.
		LibraryLinkError& operator=(LibraryLinkError&& e) noexcept;

		/// The destructor closes the link that was used to send message parameters, if any
		~LibraryLinkError() override;

		/**
		 * Set debug info
		 * @param dbg - additional information helpful in debugging
		 */
		void setDebugInfo(const std::string& dbg) {
			debugInfo = std::runtime_error {dbg};
		}

		/**
		 *   @brief Get the value of error code
		 **/
		IdType id() const noexcept {
			return errorId;
		}

		/**
		 *   @brief Alias for id() to preserve backwards compatibility
		 **/
		IdType which() const noexcept {
			return errorId;
		}

		/**
		 *   @brief Get the value of error code
		 **/
		[[nodiscard]] std::string name() const noexcept {
			return what();
		}

		/**
		 *   @brief Get the value of error code
		 **/
		[[nodiscard]] std::string message() const noexcept {
			return messageTemplate.what();
		}

		/**
		 *   @brief Get debug info
		 **/
		[[nodiscard]] std::string debug() const noexcept {
			return debugInfo.what();
		}

		/**
		 * @brief	Store arbitrary number of message parameters in a List expression on a loopback link.
		 * 			They will travel with the exception until \c sendParameters is called on the exception.
		 * @tparam 	T - any type(s) that WSStream supports
		 * @param 	libData - WolframLibraryData, if nullptr, the parameters will not be send
		 * @param 	params - any number of message parameters
		 */
		template<typename... T>
		void setMessageParameters(WolframLibraryData libData, T&&... params);

		/**
		 * @brief	Send parameters stored in the loopback link to top-level.
		 * 			They will be assigned as a List to symbol passed in \p WLSymbol parameter.
		 * @param 	libData - WolframLibraryData, if nullptr, the parameters will not be send
		 * @param	WLSymbol - symbol to assign parameters to in top-level
		 * @return	LLErrorCode because this function is noexcept
		 */
		IdType sendParameters(WolframLibraryData libData, const std::string& WLSymbol = getExceptionDetailsSymbol()) const noexcept;

		/**
		 * @brief	Get symbol that will hold details of last thrown exception.
		 * @return	a WL symbol
		 */
		static std::string getExceptionDetailsSymbol();

		/**
		 * @brief	Set custom context for the Wolfram Language symbol that will hold the details of last thrown exception.
		 * @param 	newContext - any valid WL context, it \b must end with a backtick (`)
		 */
		static void setExceptionDetailsSymbolContext(std::string newContext);

		/**
		 * @brief	Get current context of the symbol that will hold the details of last thrown exception.
		 * @return	a WL context
		 */
		static const std::string& getExceptionDetailsSymbolContext();

	private:
		/**
		 *   @brief         Constructs an exception with given error code and predefined error message
		 *   @param[in]     which - error code
		 *   @param[in]		t - error type/name
		 *   @param[in]		msg - error description
		 *   @warning		This is constructor is not supposed to be used directly by paclet developers. All errors should be thrown by ErrorManager.
		 **/
		LibraryLinkError(IdType which, const std::string& t, const std::string& msg)
			: std::runtime_error(t), errorId(which), messageTemplate(msg.c_str()) {}

		/**
		 * @brief	Helper functions that opens a loopback link given a WSTP environment
		 * @param 	env - WSTP environment
		 * @return 	a loopback link (may be nullptr if function failed to create the link)
		 */
		static WSLINK openLoopback(WSENV env);

		/// A WL symbol that will hold the details of last thrown exception. It cannot be modified directly, you can only change its context.
		static constexpr const char* exceptionDetailsSymbol = "$LastFailureParameters";

		/// Context for the exceptionDetailsSymbol. It needs to be adjustable because every paclet loads LLU into its own context.
		static std::string exceptionDetailsSymbolContext;

		IdType errorId;
		std::runtime_error messageTemplate;
		std::runtime_error debugInfo {""};
		WSLINK messageParams = nullptr;
	};

	template<typename... T>
	void LibraryLinkError::setMessageParameters(WolframLibraryData libData, T&&... params) {
		messageParams = openLoopback(libData->getWSLINKEnvironment(libData));
		if (!messageParams) {
			return;
		}
		WSStream<WS::Encoding::UTF8> loopback {messageParams};
		constexpr auto messageParamsCount = sizeof...(T);
		loopback << WS::List(static_cast<int>(messageParamsCount));
		Unused((loopback << ... << params));
	}
} /* namespace LLU */

#endif /* LLU_ERRORLOG_LIBRARYLINKERROR_H_ */
