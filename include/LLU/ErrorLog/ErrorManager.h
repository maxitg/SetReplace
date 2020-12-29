/**
 * @file	ErrorManager.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	March 21, 2019
 * @brief	Definition of the ErrorManager class responsible for error registration and throwing.
 */
#ifndef LLU_ERRORLOG_ERRORMANAGER_H
#define LLU_ERRORLOG_ERRORMANAGER_H

#include <algorithm>
#include <initializer_list>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "LLU/ErrorLog/LibraryLinkError.h"
#include "LLU/LibraryData.h"

namespace LLU {

	/**
	 * @class	ErrorManager
	 * @brief	"Static" class responsible for error registration and throwing
	 *
	 * ErrorManager holds a map with all errors that may be thrown from paclet code. These are: LLU errors, framework errors (e.g. MDevices)
	 * and paclet-specific errors which should be registered (for example in WolframLibrary_initialize) using registerPacletErrors function.
	 * Developers must never throw LibraryLinkErrors directly, instead they should use one of ErrorManager::throwException overloads.
	 **/
	class ErrorManager {
	public:
		/// A type representing registered error in the form of 2 strings: short error name and longer error description
		using ErrorStringData = std::pair<std::string, std::string>;

	public:
		/**
		 * @brief Default constructor is deleted since ErrorManager is supposed to be completely static
		 */
		ErrorManager() = delete;

		/**
		 * @brief 	Function used to register paclet-specific errors.
		 * @param 	errors - a list of pairs: {"ErrorName", "Short string with error description"}
		 */
		static void registerPacletErrors(const std::vector<ErrorStringData>& errors);

		/**
		 * @brief	Throw exception with given name.
		 * 			Optionally, pass arbitrary details of the exception occurrence and they will be stored on a loopback link in the exception object.
		 * 			Those details may later be sent via WSTP to top-level and assigned as a List to to the symbol specified
		 * 			in ErrorManager::exceptionDetailsSymbol. To trigger exception details transfer one should call LibraryLinkError::sendParameters
		 * 			on the exception object. However, if ErrorManager::sendParametersImmediately is set to true, this call will be done automatically
		 * 			in throwException.
		 * @tparam 	T - type template parameter pack
		 * @param 	errorName - name of error to be thrown, must be registered beforehand
		 * @param 	args - any number of arguments that will replace TemplateSlots (``, `1`, `xx`, etd) in the message text in top-level
		 * @note	This function requires a copy of WolframLibraryData to be saved in WolframLibrary_initialize via LibraryData::setLibraryData
		 * 			or MArgumentManager::setLibraryData.
		 */
		template<typename... T>
		[[noreturn]] static void throwException(const std::string& errorName, T&&... args);

		/**
		 * @brief	Throw exception with given name.
		 * 			Optionally, pass arbitrary details of the exception occurrence and they will be stored on a loopback link in the exception object.
		 * 			Those details may later be sent via WSTP to top-level and assigned as a List to to the symbol specified
		 * 			in ErrorManager::exceptionDetailsSymbol. To trigger exception details transfer one should call LibraryLinkError::sendParameters
		 * 			on the exception object. However, if ErrorManager::sendParametersImmediately is set to true, this call will be done automatically
		 * 			in throwException.
		 * @tparam 	T - type template parameter pack
		 * @param	libData - a copy of WolframLibraryData which should be used to extract the WSLINK for WSTP connection
		 * @param 	errorName - name of error to be thrown, must be registered beforehand
		 * @param 	args - any number of arguments that will replace TemplateSlots (``, `1`, `xx`, etd) in the message text in top-level
		 */
		template<typename... T>
		[[noreturn]] static void throwException(WolframLibraryData libData, const std::string& errorName, T&&... args);

		/**
		 * @brief 	Throw exception of given class that carries the error with given name.
		 *
		 * This is useful if you want to throw custom exception classes from your paclet and still see the nice Failure objects in top-level.
		 *
		 * @tparam	Error - custom exception class it must define a constructor that takes a LibraryLinkError as first parameter
		 * but it doesn't have to derive from LibraryLinkError
		 * @param 	errorName - name of error to be thrown
		 * @param 	args - additional arguments that will be perfectly forwarded to the constructor of Error class
		 */
		template<class Error, typename... Args>
		[[noreturn]] static void throwCustomException(const std::string& errorName, Args&&... args);

		/**
		 * @brief	Throw exception with given name and additional information that might be helpful in debugging.
		 * 			Optionally, pass arbitrary details of the exception occurrence and they will be stored on a loopback link in the exception object.
		 * 			Those details may later be sent via WSTP to top-level and assigned as a List to to the symbol specified
		 * 			in ErrorManager::exceptionDetailsSymbol. To trigger exception details transfer one should call LibraryLinkError::sendParameters
		 * 			on the exception object. However, if ErrorManager::sendParametersImmediately is set to true, this call will be done automatically
		 * 			in throwException.
		 * 			The debugInfo is a string stored inside the LibraryLinkError object. It is never transferred to top-level but might be for example logged
		 * 			to a file in a "catch" block in C++ code.
		 * @tparam 	T - type template parameter pack
		 * @param 	errorName - name of error to be thrown, must be registered beforehand
		 * @param	debugInfo - additional message with debug info, this message will not be passed to top-level Failure object
		 * @param 	args - any number of arguments that will replace TemplateSlots (``, `1`, `xx`, etd) in the message text in top-level
		 * @note	This function requires a copy of WolframLibraryData to be saved in WolframLibrary_initialize via LibraryData::setLibraryData
		 * 			or MArgumentManager::setLibraryData.
		 */
		template<typename... T>
		[[noreturn]] static void throwExceptionWithDebugInfo(const std::string& errorName, const std::string& debugInfo, T&&... args);

		/**
		 * @brief	Throw exception with given name and additional information that might be helpful in debugging.
		 * 			Optionally, pass arbitrary details of the exception occurrence and they will be stored on a loopback link in the exception object.
		 * 			Those details may later be sent via WSTP to top-level and assigned as a List to to the symbol specified
		 * 			in ErrorManager::exceptionDetailsSymbol. To trigger exception details transfer one should call LibraryLinkError::sendParameters
		 * 			on the exception object. However, if ErrorManager::sendParametersImmediately is set to true, this call will be done automatically
		 * 			in throwException.
		 * 			The debugInfo is a string stored inside the LibraryLinkError object. It is never transferred to top-level but might be for example logged
		 * 			to a file in a "catch" block in C++ code.
		 * @tparam 	T - type template parameter pack
		 * @param	libData - a copy of WolframLibraryData which should be used to extract the WSLINK for WSTP connection
		 * @param 	errorName - name of error to be thrown, must be registered beforehand
		 * @param	debugInfo - additional message with debug info, this message will not be passed to top-level Failure object
		 * @param 	args - any number of arguments that will replace TemplateSlots (``, `1`, `xx`, etd) in the message text in top-level
		 */
		template<typename... T>
		[[noreturn]] static void
		throwExceptionWithDebugInfo(WolframLibraryData libData, const std::string& errorName, const std::string& debugInfo, T&&... args);

		/**
		 * @brief   Sets new value for the sendParametersImmediately flag. Pass false to make sure that exception do not send their parameters to top-level when
		 * they are thrown. This is essential in multithreaded applications since the WL symbol that parameters are assigned to may be treated as a global
		 * shared resource. It is recommended to use this method in WolframLibrary_initialize.
		 * @param 	newValue - new value for the sendParametersImmediately flag
		 */
		static void setSendParametersImmediately(bool newValue) {
			sendParametersImmediately = newValue;
		}

		/**
		 * @brief 	Get the current value of sendParametersImmediately flag.
		 * @return 	current value of sendParametersImmediately flag.
		 */
		static bool getSendParametersImmediately() {
			return sendParametersImmediately;
		}

		/**
		 * @brief Function used to send all registered errors to top-level Mathematica code.
		 *
		 * Sending registered errors allows for nice and meaningful Failure objects to be generated when paclet function fails in top level,
		 * instead of usual LibraryFunctionError expressions.
		 * @param mlp - active WSTP connection
		 */
		static void sendRegisteredErrorsViaWSTP(WSLINK mlp);

	private:
		/// Errors are stored in a map with elements of the form { "ErrorName", immutable LibraryLinkError object }
		using ErrorMap = std::unordered_map<std::string, const LibraryLinkError>;

	private:
		/**
		 * @brief 	Use this function to add new entry to the map of registered errors.
		 * @param 	errorData - a pair of strings: error name + error description
		 */
		static void set(const ErrorStringData& errorData);

		/**
		 * @brief Find error by id.
		 * @param errorId - error id
		 * @return const& to the desired error
		 */
		static const LibraryLinkError& findError(int errorId);

		/**
		 * @brief Find error by name.
		 * @param errorName - error name
		 * @return const& to the desired error
		 */
		static const LibraryLinkError& findError(const std::string& errorName);

		/***
		 * @brief Initialization of static error map
		 * @param initList - list of errors used internally by LLU
		 * @return reference to static error map
		 */
		static ErrorMap registerLLUErrors(std::initializer_list<ErrorStringData> initList);

		/// Static map of registered errors
		static ErrorMap& errors();

		/// Id that will be assigned to the next registered error.
		static int& nextErrorId();

		/// Boolean flag that determines whether ErrorManager should trigger the transfer of message parameters to top-level for LibraryLinkErrors it throws.
		static bool sendParametersImmediately;
	};

	template<typename... T>
	[[noreturn]] void ErrorManager::throwException(const std::string& errorName, T&&... args) {
		throwException(LibraryData::uncheckedAPI(), errorName, std::forward<T>(args)...);
	}

	template<typename... T>
	[[noreturn]] void ErrorManager::throwException(WolframLibraryData libData, const std::string& errorName, T&&... args) {
		throwExceptionWithDebugInfo(libData, errorName, "", std::forward<T>(args)...);
	}

	template<class Error, typename... Args>
	[[noreturn]] void ErrorManager::throwCustomException(const std::string& errorName, Args&&... args) {
		throw Error(findError(errorName), std::forward<Args>(args)...);
	}

	template<typename... T>
	[[noreturn]] void ErrorManager::throwExceptionWithDebugInfo(const std::string& errorName, const std::string& debugInfo, T&&... args) {
		throwExceptionWithDebugInfo(LibraryData::uncheckedAPI(), errorName, debugInfo, std::forward<T>(args)...);
	}

	template<typename... T>
	[[noreturn]] void
	ErrorManager::throwExceptionWithDebugInfo(WolframLibraryData libData, const std::string& errorName, const std::string& debugInfo, T&&... args) {
		auto e = findError(errorName);
		e.setDebugInfo(debugInfo);
		if (libData && sizeof...(args) > 0) {
			e.setMessageParameters(libData, std::forward<T>(args)...);
			if (sendParametersImmediately) {
				e.sendParameters(libData);
			}
		}
		throw std::move(e);
	}

} /* namespace LLU */

#endif	  // LLU_ERRORLOG_ERRORMANAGER_H
