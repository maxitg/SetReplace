/**
 * @file	Logger.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Define Logger namespace containing logging related declarations and convenience macros.
 */
#ifndef LLU_ERRORLOG_LOGGER_H
#define LLU_ERRORLOG_LOGGER_H

#include <initializer_list>
#include <mutex>
#include <string>
#include <utility>

#include "LLU/LibraryData.h"
#include "LLU/WSTP/WSStream.hpp"

// Configuration macros to set desired level of logging at build time:

/**
 * @def LLU_LOG_DEBUG
 * Define LLU_LOG_DEBUG to enable all log levels
 */
#ifdef LLU_LOG_DEBUG
#define LLU_LOG_LEVEL_DEBUG
#define LLU_LOG_WARNING
#define LLU_LOG_DEBUG // workaround for a Doxygen bug
#endif

/**
 * @def LLU_LOG_WARNING
 * Define LLU_LOG_WARNING to enable warning and error logs. Debug logs will be ignored.
 */
#ifdef LLU_LOG_WARNING
#define LLU_LOG_LEVEL_WARNING
#define LLU_LOG_ERROR
#endif

/**
 * @def LLU_LOG_ERROR
 * Define LLU_LOG_ERROR to enable only error logs. Debug and warning logs will be ignored.
 */
#ifdef LLU_LOG_ERROR
#define LLU_LOG_LEVEL_ERROR
#endif

// Convenience macros to use in the code:

#ifdef LLU_LOG_LEVEL_DEBUG
/**
 * Log a message (arbitrary sequence of arguments that can be passed via WSTP) as debug information, the log will consist of the line number, file name,
 * function name and user-provided args.
 * Formatting can be customized on the Wolfram Language side.
 * @note This macro is only active with LLU_LOG_DEBUG compilation flag.
 */
#define LLU_DEBUG(...) LLU::Logger::log<LLU::Logger::Level::Debug>(__LINE__, __FILE__, __func__, __VA_ARGS__)
#else
#define LLU_DEBUG(...) ((void)0)
#endif

#ifdef LLU_LOG_LEVEL_WARNING
/**
 * Log a message (arbitrary sequence of arguments that can be passed via WSTP) as warning, the log will consist of the line number, file name,
 * function name and user-provided args.
 * Formatting can be customized on the Wolfram Language side.
 * @note This macro is only active with LLU_LOG_DEBUG or LLU_LOG_WARNING compilation flag.
 */
#define LLU_WARNING(...) LLU::Logger::log<LLU::Logger::Level::Warning>(__LINE__, __FILE__, __func__, __VA_ARGS__)
#else
#define LLU_WARNING(...) ((void)0)
#endif

#ifdef LLU_LOG_LEVEL_ERROR
/**
 * Log a message (arbitrary sequence of arguments that can be passed via WSTP) as error, the log will consist of the line number, file name,
 * function name and user-provided args.
 * Formatting can be customized on the Wolfram Language side.
 * @note This macro is only active with LLU_LOG_DEBUG, LLU_LOG_WARNING or LLU_LOG_ERROR compilation flag.
 */
#define LLU_ERROR(...) LLU::Logger::log<LLU::Logger::Level::Error>(__LINE__, __FILE__, __func__, __VA_ARGS__)
#else
#define LLU_ERROR(...) ((void)0)
#endif

namespace LLU {

	/**
	 * Logger class is responsible for sending log messages via WSTP to Mathematica.
	 * It may be more convenient to use one of the LLU_DEBUG/WARNING/ERROR macros instead of calling Logger methods directly.
	 */
	class Logger {
	public:
		/// Possible log severity levels
		enum class Level { Debug, Warning, Error };

		/**
		 * @brief	Send a log message of given severity.
		 * @tparam 	L - log level, severity of the log
		 * @tparam 	T - any number of WSTP-supported types
		 * @param 	libData - WolframLibraryData, if nullptr - no logging happens
		 * @param 	line - line number where the log was called
		 * @param 	fileName - name of the file in which the log was called
		 * @param 	function - function in which the log was called
		 * @param 	args - additional parameters carrying the actual log message contents
		 * @warning This function communicates with WSTP and if this communication goes wrong, WSStream may throw
		 * 			so be careful when logging in destructors.
		 */
		template<Level L, typename... T>
		static void log(WolframLibraryData libData, int line, const std::string& fileName, const std::string& function, T&&... args);

		/**
		 * @brief	Send a log message of given severity.
		 * @tparam 	L - log level, severity of the log
		 * @tparam 	T - any number of WSTP-supported types
		 * @param 	line - line number where the log was called
		 * @param 	fileName - name of the file in which the log was called
		 * @param 	function - function in which the log was called
		 * @param 	args - additional parameters carrying the actual log message contents
		 * @warning This function communicates with WSTP and if this communication goes wrong, WSStream may throw
		 * 			so be careful when logging in destructors.
		 */
		template<Level L, typename... T>
		static void log(int line, const std::string& fileName, const std::string& function, T&&... args);

		/**
		 * Converts Logger::Level value to std::string
		 * @param l - log level
		 * @return a string representation of the input log level
		 */
		static std::string to_string(Level l);

		/**
		 * Set new context for the top-level symbol that will handle logging.
		 * @param context - new context, must end with "`"
		 */
		static void setContext(std::string context) {
			logSymbolContext = std::move(context);
		}

		/**
		 * Get the top-level symbol with full context, to which all logs are sent
		 * @return top-level symbol to which logs are sent
		 */
		static std::string getSymbol() {
			return logSymbolContext + topLevelLogCallback;
		}

	private:
		/// Name of the WL function, to which log elements will be sent as arguments via WSTP.
		static constexpr const char* topLevelLogCallback = "Logger`LogHandler";
		static std::mutex mlinkGuard;
		static std::string logSymbolContext;
	};

	/**
	 * Sends a Logger::Level value via WSStream
	 * @tparam 	EIn - WSStream input encoding
	 * @tparam 	EOut - WSStream output encoding
	 * @param 	ms - reference to the WSStream object
	 * @param 	l - log level
	 * @return	reference to the input stream
	 */
	template<WS::Encoding EIn, WS::Encoding EOut>
	static WSStream<EIn, EOut>& operator<<(WSStream<EIn, EOut>& ms, Logger::Level l) {
		return ms << Logger::to_string(l);
	}

	template<Logger::Level L, typename... T>
	void Logger::log(WolframLibraryData libData, int line, const std::string& fileName, const std::string& function, T&&... args) {
		if (!libData) {
			return;
		}
		std::lock_guard<std::mutex> lock(mlinkGuard);

		WSStream<WS::Encoding::UTF8> mls {libData->getWSLINK(libData)};
		mls << WS::Function("EvaluatePacket", 1);
		mls << WS::Function(getSymbol(), 4 + sizeof...(T));
		mls << L << line << fileName << function;
		Unused((mls << ... << args));
		libData->processWSLINK(mls.get());
		auto pkt = WSNextPacket(mls.get());
		if (pkt == RETURNPKT) {
			mls << WS::NewPacket;
		}
	}

	template<Logger::Level L, typename... T>
	void Logger::log(int line, const std::string& fileName, const std::string& function, T&&... args) {
		log<L>(LibraryData::API(), line, fileName, function, std::forward<T>(args)...);
	}

}  // namespace LLU
#endif	  // LLU_ERRORLOG_LOGGER_H
