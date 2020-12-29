/**
 * @file
 * @date	Nov 26, 2017
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief	Implementation file with miscellaneous definitions used throughout the WSTP-related part of LibraryLinkUtilities
 */
#include "LLU/WSTP/Utilities.h"

#include "LLU/ErrorLog/ErrorManager.h"

namespace LLU::WS {

	const std::string& Symbol::getHead() const {
		return head;
	}

	void Symbol::setHead(std::string h) {
		head = std::move(h);
	}

	int Function::getArgc() const {
		return argc;
	}

	void Function::setArgc(int newArgc) {
		argc = newArgc;
	}

	namespace Detail {
		namespace {
			std::string getWSErrorText(WSLINK mlp) {
				std::string err = "Error code reported by WSTP: " + std::to_string(WSError(mlp)) + "\n";
				const auto* mlErrorMsg = WSErrorMessage(mlp);
				if (mlErrorMsg) {
					err += "\"" + std::string(mlErrorMsg) + "\"";
					WSReleaseErrorMessage(mlp, mlErrorMsg);
				}
				WSClearError(mlp);
				return err;
			}
		}  // namespace

		void checkError(WSLINK m, int statusOk, const std::string& errorName, const std::string& debugInfo) {
			if (statusOk == 0) {
				ErrorManager::throwExceptionWithDebugInfo(errorName, getWSErrorText(m) + "\nDebug info: " + debugInfo);
			}
		}

		void throwLLUException(const std::string& errorName, const std::string& debugInfo) {
			ErrorManager::throwExceptionWithDebugInfo(errorName, debugInfo);
		}

		WSLINK getNewLoopback(WSLINK m) {
			int err = 0;
			auto* loopback = WSLoopbackOpen(WSLinkEnvironment(m), &err);
			if (loopback == nullptr || err != WSEOK) {
				ErrorManager::throwExceptionWithDebugInfo(ErrorName::WSCreateLoopbackError, "Error code: " + std::to_string(err));
			}
			return loopback;
		}

		int countExpressionsInLoopbackLink(WSLINK& lpbckLink) {
			auto* helperLink = getNewLoopback(lpbckLink);
			int exprCnt = 0;
			while (WSTransferExpression(helperLink, lpbckLink) != 0) {
				exprCnt++;
			}
			WSClose(lpbckLink);
			lpbckLink = helperLink;
			return exprCnt;
		}
	}  // namespace Detail

}	 // namespace LLU::WS
