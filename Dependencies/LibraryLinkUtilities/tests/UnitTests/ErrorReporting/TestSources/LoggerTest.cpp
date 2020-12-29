/**
 * @file	LoggerTest.cpp
 * @brief 	Unit tests for Logger
 */
#include <chrono>
#include <random>
#include <sstream>
#include <thread>

#include <LLU/ErrorLog/Logger.h>
#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/ProgressMonitor.h>

using LLU::LibraryLinkError;
namespace LLErrorCode = LLU::ErrorCode;

LIBRARY_LINK_FUNCTION(GreaterAt) {
	LLU_DEBUG("Library function entered with ", Argc, " arguments.");
	auto err = LLErrorCode::NoError;
	try {
		LLU_DEBUG("Starting try-block, current error code: ", err);
		LLU::MArgumentManager mngr(Argc, Args, Res);
		auto fileName = mngr.getString(0);
		if (fileName.find(':') != std::string::npos) {
			LLU_WARNING("File name ", fileName, " contains a possibly problematic character \":\".");
		}
		LLU_DEBUG("Input tensor is of type: ", mngr.getTensorType(1));
		if (mngr.getTensorType(1) == MType_Complex) {
			LLU_ERROR("Input tensor contains complex numbers which is not supported");
			mngr.setBoolean(false);
			return err;
		}
		auto t = mngr.getTensor<mint>(1);
		auto index1 = mngr.getInteger<mint>(2);
		auto index2 = mngr.getInteger<mint>(3);
		if (index1 <= 0 || index2 <= 0) {
			LLU::ErrorManager::throwExceptionWithDebugInfo(LLU::ErrorName::TensorIndexError,
														   "Indices (" + std::to_string(index1) + ", " + std::to_string(index2) + ") must be positive.");
		}
		LLU_DEBUG("Comparing ", t.at(index1 - 1), " with ", t.at(index2 - 1));
		mngr.setBoolean(t.at(index1 - 1) > t.at(index2 - 1));
	} catch (const LibraryLinkError& e) {
		LLU_ERROR("Caught LLU exception ", e.what(), ": ", e.debug());
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	return 0;
}

LIBRARY_LINK_FUNCTION(LogDemo) {
	LLU_DEBUG("Library function entered with ", Argc, " arguments.");
	auto err = LLErrorCode::NoError;
	try {
		LLU::MArgumentManager mngr(Argc, Args, Res);
		auto index = mngr.getInteger<mint>(0);
		if (index >= Argc) {
			LLU_WARNING("Index ", index, " is too big for the number of arguments: ", Argc, ". Changing to ", Argc - 1);
			index = Argc - 1;
		}
		auto value = mngr.getInteger<mint>(static_cast<unsigned int>(index));
		mngr.setInteger(value);
	} catch (const LibraryLinkError& e) {
		LLU_ERROR("Caught LLU exception ", e.what(), ": ", e.debug());
		err = e.which();
	}
	return err;
}

LIBRARY_LINK_FUNCTION(LogsFromThreads) {
	using namespace std::chrono_literals;
	auto err = LLErrorCode::NoError;
	try {
		std::random_device rd;	  // Will be used to obtain a seed for the random number engine
		std::mt19937 gen(rd());
		std::uniform_int_distribution<> dis(10, 1000);

		LLU::MArgumentManager mngr(Argc, Args, Res);
		auto threadCount = mngr.getInteger<mint>(0);
		std::vector<std::thread> threads(threadCount);
		LLU_DEBUG("Starting ", threadCount, " threads.");
		for (int i = 0; i < threadCount; ++i) {
			threads[i] = std::thread(
				[i](int sleepTime) {
					LLU_DEBUG("Thread ", i, " going to sleep.");
					std::this_thread::sleep_for(std::chrono::milliseconds(sleepTime));
					LLU_DEBUG("Thread ", i, " slept for ", sleepTime, "ms.");
				},
				dis(gen));
		}
		for (auto& t : threads) {
			if (t.joinable()) {
				t.join();
			}
		}
		LLU_DEBUG("All threads joined.");
	} catch (const LibraryLinkError& e) {
		LLU_ERROR("Caught LLU exception ", e.what(), ": ", e.debug());
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}