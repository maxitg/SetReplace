/**
 * @file	Logger.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Implementation of functions defined in Logger.h.
 */
#include "LLU/ErrorLog/Logger.h"

#include "LLU/LibraryLinkFunctionMacro.h"
#include "LLU/MArgumentManager.h"

namespace LLU {
	std::mutex Logger::mlinkGuard;
	std::string Logger::logSymbolContext;

	std::string Logger::to_string(Level l) {
		switch (l) {
			case Level::Debug: return "Debug";
			case Level::Warning: return "Warning";
			case Level::Error: return "Error";
			default: return "Unknown";
		}
	}

	/**
	 * LibraryLink function that LLU will call to set the context for the symbol, to which log details are assigned.
	 * This symbol is usually in the paclet's Private` context and it cannot be hardcoded in LLU.
	 */
	LIBRARY_LINK_FUNCTION(setLoggerContext) {
		auto err = ErrorCode::NoError;
		try {
			MArgumentManager mngr {libData, Argc, Args, Res};
			auto newContext = mngr.getString(0);
			Logger::setContext(newContext);
			mngr.setString(Logger::getSymbol());
		} catch (LibraryLinkError& e) { err = e.which(); } catch (...) {
			err = ErrorCode::FunctionError;
		}
		return err;
	}
}	 // namespace LLU