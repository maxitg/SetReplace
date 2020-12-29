/**
 * @file	progressTest.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief 	Unit tests for ProgressMonitor
 */
#include <chrono>
#include <thread>

#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>
#include <LLU/ProgressMonitor.h>

using namespace std::chrono_literals;

namespace LLErrorCode = LLU::ErrorCode;
using LLU::LibraryLinkError;
using LLU::MArgumentManager;
using LLU::ProgressMonitor;

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	return 0;
}

/**
 * @brief Simple function that just sleeps in a loop moving the progress bar in a steady pace
 *
 * This function takes two arguments:
 * 1. (Real) Total time (in seconds) for the function to complete
 * 2. (ProgressMonitor) Shared instance of an MTensor automatically wrapped in ProgressMonitor by MArgumentManager
 */
LIBRARY_LINK_FUNCTION(UniformProgress) {
	auto err = LLErrorCode::NoError;
	try {
		MArgumentManager mngr(Argc, Args, Res);
		auto totalTime = mngr.getReal(0);
		auto numOfSteps = static_cast<int>(std::ceil(totalTime * 10));
		auto pm = mngr.getProgressMonitor(1.0 / numOfSteps);
		for (int i = 0; i < numOfSteps; ++i) {
			std::this_thread::sleep_for(100ms);
			++pm;
		}
		mngr.setInteger(42);
	} catch (const LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}

/**
 * @brief A function similar to "UniformProgress" but it does not report progress. It only checks for Abort.
 *
 * This function takes one argument:
 * 1. (Real) Total time (in seconds) for the function to complete
 */
LIBRARY_LINK_FUNCTION(NoProgressButAbortable) {
	auto err = LLErrorCode::NoError;
	try {
		MArgumentManager mngr(Argc, Args, Res);
		auto totalTime = mngr.getReal(0);
		auto numOfSteps = static_cast<int>(std::ceil(totalTime * 10));
		for (int i = 0; i < numOfSteps; ++i) {
			std::this_thread::sleep_for(100ms);
			ProgressMonitor::checkAbort();
		}
		mngr.setInteger(42);
	} catch (const LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}

/**
 * @brief A function similar to "UniformProgress" but it does not report progress nor checks for Abort.
 *
 * This function takes one argument:
 * 1. (Real) Total time (in seconds) for the function to complete
 */
LIBRARY_LINK_FUNCTION(NoProgressNotAbortable) {
	auto err = LLErrorCode::NoError;
	try {
		MArgumentManager mngr(Argc, Args, Res);
		auto totalTime = mngr.getReal(0);
		auto numOfSteps = static_cast<int>(std::ceil(totalTime * 10));
		for (int i = 0; i < numOfSteps; ++i) {
			std::this_thread::sleep_for(100ms);
		}
		mngr.setInteger(42);
	} catch (const LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}

/**
 * @brief Simple function that is divided into 3 phases: data preparation (20% of time), data processing (50%) and formatting the result.
 *
 * This function takes two arguments:
 * 1. (Real) Total time (in seconds) for the function to complete
 * 2. (ProgressMonitor) Shared instance of an MTensor automatically wrapped in ProgressMonitor by MArgumentManager
 */
LIBRARY_LINK_FUNCTION(PrepareProcessAndFormat) {
	auto err = LLErrorCode::NoError;
	try {
		MArgumentManager mngr(Argc, Args, Res);
		auto totalTime = mngr.getReal(0);
		auto pm = mngr.getProgressMonitor();

		auto prepTime = std::chrono::milliseconds(static_cast<int>(1000 * 0.3 * totalTime));
		// Prepare data
		std::this_thread::sleep_for(prepTime);
		pm.set(0.3);

		// How much time to sleep for one iteration of data processing
		auto procTime = std::chrono::milliseconds(static_cast<int>(1000 * 0.5 * totalTime));
		std::this_thread::sleep_for(procTime);
		pm.set(0.8);

		auto formatResTime = std::chrono::milliseconds(static_cast<int>(1000 * 0.2 * totalTime));
		// Format the result
		std::this_thread::sleep_for(formatResTime);
		pm.set(1);

		mngr.setInteger(42);
	} catch (const LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}

/**
 * @brief Simple function that shows how to decrease progress if some operation must be repeated
 *
 * This function takes two arguments:
 * 1. (Real) Total time (in seconds) for the function to complete
 * 2. (ProgressMonitor) Shared instance of an MTensor automatically wrapped in ProgressMonitor by MArgumentManager
 */
LIBRARY_LINK_FUNCTION(DecreaseProgress) {
	auto err = LLErrorCode::NoError;
	try {
		MArgumentManager mngr(Argc, Args, Res);
		auto totalTime = mngr.getReal(0);
		auto pm = mngr.getProgressMonitor(0.01);

		auto prepTime = std::chrono::milliseconds(static_cast<int>(1000 * 0.3 * totalTime));
		std::this_thread::sleep_for(prepTime);	  // Prepare data
		pm.set(0.3);

		// How much time to sleep for one iteration of data processing
		auto procTime = std::chrono::milliseconds(static_cast<int>(1000 * 0.01 * totalTime));
		bool shouldRepeat = true;
		bool processingDone = false;
		while (!processingDone) {
			for (int i = 0; i < 50; ++i) {
				// Process data
				++pm;
				std::this_thread::sleep_for(procTime);

				// Simulate a failure in the middle of data processing. We have to start over, so progress monitor value is decreased.
				if (i == 35 && shouldRepeat) {
					shouldRepeat = false;
					pm.set(0.3);
					break;
				}
				if (i == 49) {
					processingDone = true;
				}
			}
		}

		auto formatResTime = std::chrono::milliseconds(static_cast<int>(1000 * 0.2 * totalTime));
		// Format the result
		std::this_thread::sleep_for(formatResTime);
		pm.set(1);

		mngr.setInteger(42);
	} catch (const LibraryLinkError& e) {
		err = e.which();
	} catch (...) {
		err = LLErrorCode::FunctionError;
	}
	return err;
}