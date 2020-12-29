/**
 * @file	LibraryLinkError.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 *
 * @brief	Contains definitions of ErrorManager members and implementation of interface function sendRegisteredErrors used by PacletFailure framework in LLU
 *
 */
#include "LLU/ErrorLog/LibraryLinkError.h"

#include "LLU/LibraryLinkFunctionMacro.h"
#include "LLU/MArgumentManager.h"
#include "LLU/WSTP/WSStream.hpp"

namespace LLU {

	std::string LibraryLinkError::exceptionDetailsSymbolContext;

	void LibraryLinkError::setExceptionDetailsSymbolContext(std::string newContext) {
		exceptionDetailsSymbolContext = std::move(newContext);
	}

	const std::string& LibraryLinkError::getExceptionDetailsSymbolContext() {
		return exceptionDetailsSymbolContext;
	}

	std::string LibraryLinkError::getExceptionDetailsSymbol() {
		return exceptionDetailsSymbolContext + exceptionDetailsSymbol;
	}

	WSLINK LibraryLinkError::openLoopback(WSENV env) {
		int err = WSEUNKNOWN;
		auto* link = WSLoopbackOpen(env, &err);
		if (err != WSEOK) {
			link = nullptr;
		}
		return link;
	}

	LibraryLinkError::LibraryLinkError(const LibraryLinkError& e) noexcept
		: std::runtime_error(e), errorId(e.errorId), messageTemplate(e.messageTemplate), debugInfo(e.debugInfo) {
		if (e.messageParams) {
			messageParams = openLoopback(WSLinkEnvironment(e.messageParams));
			if (!messageParams) {
				return;
			}
			auto* mark = WSCreateMark(e.messageParams);
			WSTransferToEndOfLoopbackLink(messageParams, e.messageParams);
			WSSeekMark(e.messageParams, mark, 0);
			WSDestroyMark(e.messageParams, mark);
		}
	}

	LibraryLinkError& LibraryLinkError::operator=(const LibraryLinkError& e) noexcept {
		LibraryLinkError tmp {e};
		*this = std::move(tmp);
		return *this;
	}

	LibraryLinkError::LibraryLinkError(LibraryLinkError&& e) noexcept
		// NOLINTNEXTLINE(performance-move-constructor-init) : deliberate and harmless
		: std::runtime_error(e), errorId(e.errorId), messageTemplate(e.messageTemplate), debugInfo(e.debugInfo), messageParams(e.messageParams) {
		e.messageParams = nullptr;
	}

	LibraryLinkError& LibraryLinkError::operator=(LibraryLinkError&& e) noexcept {
		std::runtime_error::operator=(e);
		errorId = e.errorId;
		messageTemplate = e.messageTemplate;
		debugInfo = e.debugInfo;
		if (messageParams) {
			WSClose(messageParams);
		}
		messageParams = e.messageParams;
		e.messageParams = nullptr;
		return *this;
	}

	LibraryLinkError::~LibraryLinkError() {
		if (messageParams) {
			WSClose(messageParams);
		}
	}

	auto LibraryLinkError::sendParameters(WolframLibraryData libData, const std::string& WLSymbol) const noexcept -> IdType {
		try {
			if (libData) {
				WSStream<WS::Encoding::UTF8> mls {libData->getWSLINK(libData)};
				mls << WS::Function("EvaluatePacket", 1);
				mls << WS::Function("Set", 2);
				mls << WS::Symbol(WLSymbol);
				if (WSTransferToEndOfLoopbackLink(mls.get(), messageParams) == 0) {
					return ErrorCode::FunctionError;
				}
				libData->processWSLINK(mls.get());
				auto pkt = WSNextPacket(mls.get());
				if (pkt == RETURNPKT) {
					mls << WS::NewPacket;
				}
			}
		} catch (const LibraryLinkError& e) {
			return e.which();
		} catch (...) {
			return ErrorCode::FunctionError;
		}
		return ErrorCode::NoError;
	}

	/**
	 * LibraryLink function that LLU will call to set the context for the symbol, to which exception details are assigned.
	 * This symbol is usually in the paclet's Private` context and it cannot be hardcoded in LLU.
	 */
	LIBRARY_LINK_FUNCTION(setExceptionDetailsContext) {
		auto err = ErrorCode::NoError;
		try {
			MArgumentManager mngr {libData, Argc, Args, Res};
			auto newContext = mngr.getString(0);
			LibraryLinkError::setExceptionDetailsSymbolContext(std::move(newContext));
			mngr.setString(LibraryLinkError::getExceptionDetailsSymbol());
		} catch (LibraryLinkError& e) {
			err = e.which();
		} catch (...) {
			err = ErrorCode::FunctionError;
		}
		return err;
	}
} /* namespace LLU */
