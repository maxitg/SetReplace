/**
 * @file
 * @brief
 */
#include <numeric>
#include <thread>

#include <LLU/Async/ThreadPool.h>
#include <LLU/ErrorLog/Logger.h>
#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

using namespace std::chrono_literals;
using LLU::NumericArray;

namespace {
	std::mutex logMutex;
}

#define THREADSAFE_LOG(...)             \
	{                                   \
		std::lock_guard mlg {logMutex}; \
		LLU_DEBUG(__VA_ARGS__);         \
	}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	return 0;
}

template<typename ThreadPool>
void sleepyThreadsInPool(LLU::MArgumentManager& mngr) {
	auto numThreads = mngr.getInteger<mint>(0);
	if (numThreads <= 0) {
		numThreads = std::thread::hardware_concurrency() > 1 ? std::thread::hardware_concurrency() - 1 : 1;
	}
	THREADSAFE_LOG("Running on ", numThreads, " threads.")
	ThreadPool tp {static_cast<unsigned int>(numThreads)};
	const auto numJobs = mngr.getInteger<mint>(1);
	const auto time = mngr.getInteger<mint>(2);
	std::condition_variable allJobsDone;
	std::mutex jobCounterMutex;
	int completedJobs = 0;
	for (int i = 0; i < numJobs; ++i) {
		tp.submit([&] {
			std::this_thread::sleep_for(std::chrono::milliseconds(time));
			std::unique_lock lg {jobCounterMutex};
			if (++completedJobs == numJobs) {
				allJobsDone.notify_one();
			}
		});
	}
	THREADSAFE_LOG("Submitted ", numJobs, " jobs.")
	std::unique_lock lg {jobCounterMutex};
	allJobsDone.wait(lg, [&] { return completedJobs == numJobs; });
	THREADSAFE_LOG("All jobs finished.")
}

LLU_LIBRARY_FUNCTION(SleepyThreads) {
	sleepyThreadsInPool<LLU::ThreadPool>(mngr);
}

LLU_LIBRARY_FUNCTION(SleepyThreadsBasic) {
	sleepyThreadsInPool<LLU::BasicPool>(mngr);
}

LLU_LIBRARY_FUNCTION(SleepyThreadsWithPause) {
	auto numThreads = mngr.getInteger<mint>(0);
	if (numThreads <= 0) {
		numThreads = std::thread::hardware_concurrency() > 1 ? std::thread::hardware_concurrency() - 1 : 1;
	}
	LLU::ThreadPool tp {static_cast<unsigned int>(numThreads)};
	tp.pause();
	THREADSAFE_LOG("Running on ", numThreads, " threads. Paused.")
	const auto numJobs = mngr.getInteger<mint>(1);
	const auto time = mngr.getInteger<mint>(2);
	std::condition_variable allJobsDone;
	std::mutex jobCounterMutex;
	int completedJobs = 0;
	for (int i = 0; i < numJobs; ++i) {
		tp.submit([&] {
			std::this_thread::sleep_for(std::chrono::milliseconds(time));
			std::unique_lock lg {jobCounterMutex};
			if (++completedJobs == numJobs) {
				allJobsDone.notify_one();
			}
		});
	}
	std::this_thread::sleep_for(std::chrono::seconds(1));
	THREADSAFE_LOG("Submitted ", numJobs, " jobs. Now resuming")
	tp.resume();
	std::unique_lock lg {jobCounterMutex};
	allJobsDone.wait(lg, [&] { return completedJobs == numJobs; });
}

template<typename ThreadPool>
void accumulateInPool(LLU::MArgumentManager& mngr) {
	auto data = mngr.getGenericNumericArray<LLU::Passing::Constant>(0);
	const auto numThreads = mngr.getInteger<mint>(1);
	const auto jobSize = mngr.getInteger<mint>(2);
	ThreadPool tp {static_cast<unsigned int>(numThreads)};

	const auto numJobs = (data.getFlattenedLength() + jobSize - 1) / jobSize;
	LLU::asTypedNumericArray(data, [&](auto&& typedNA) {
		using T = typename std::remove_reference_t<decltype(typedNA)>::value_type;
		std::vector<std::future<T>> partialResults {static_cast<size_t>(numJobs) - 1};
		auto blockBegin = std::cbegin(typedNA);
		for (int i = 0; i < numJobs - 1; ++i) {
			auto blockEnd = std::next(blockBegin, jobSize);
			partialResults[i] = tp.submit(std::accumulate<typename NumericArray<T>::const_iterator, T>, blockBegin, blockEnd, T {});
			blockBegin = blockEnd;
		}
		T remainderSum = std::accumulate(blockBegin, std::cend(typedNA), T {});
		T totalSum =
			std::accumulate(std::begin(partialResults), std::end(partialResults), remainderSum, [](T currentSum, auto& fut) { return currentSum + fut.get(); });
		mngr.set(NumericArray<T> {totalSum});
	});
}

LLU_LIBRARY_FUNCTION(Accumulate) {
	accumulateInPool<LLU::ThreadPool>(mngr);
}

LLU_LIBRARY_FUNCTION(AccumulateBasic) {
	accumulateInPool<LLU::BasicPool>(mngr);
}

LLU_LIBRARY_FUNCTION(AccumulateSequential) {
	auto data = mngr.getGenericNumericArray<LLU::Passing::Constant>(0);
	LLU::asTypedNumericArray(data, [&](auto&& typedNA) {
		using T = typename std::remove_reference_t<decltype(typedNA)>::value_type;
		T totalSum = std::accumulate(std::begin(typedNA), std::end(typedNA), T{});
		mngr.set(NumericArray<T> {totalSum});
	});
}

template<typename InputIter>
std::uint64_t rangeLcm(InputIter first, InputIter last) {
	std::uint64_t lcm = 1;
	for (auto iter = first; iter != last; ++iter) {
		lcm = std::lcm(lcm, *iter);
	}
	return lcm;
}

LLU_LIBRARY_FUNCTION(LcmSequential) {
	auto data = mngr.getNumericArray<std::uint64_t, LLU::Passing::Constant>(0);
	auto lcm = rangeLcm(std::begin(data), std::end(data));
	mngr.set(NumericArray<std::uint64_t> {lcm});
}

template<typename InputIter>
std::uint64_t rangeLcm([[maybe_unused]] LLU::ThreadPool& tp, mint threshold, InputIter first, InputIter last) {
	auto dist = std::distance(first, last);
	if (dist < threshold) {
		return rangeLcm(first, last);
	}
	auto midpoint = std::next(first, dist / 2);
	auto lcmLower = tp.submit([=, &tp]() { return rangeLcm(tp, threshold, first, midpoint); });
	auto lcmUpper = rangeLcm(tp, threshold, midpoint, last);
	while (lcmLower.wait_for(std::chrono::seconds(0)) == std::future_status::timeout) {
		tp.runPendingTask();
	}
	return std::lcm(lcmLower.get(), lcmUpper);
}

LLU_LIBRARY_FUNCTION(LcmParallel) {
	auto data = mngr.getNumericArray<std::uint64_t, LLU::Passing::Constant>(0);
	const auto numThreads = mngr.getInteger<mint>(1);
	const auto jobSize = mngr.getInteger<mint>(2);
	LLU::ThreadPool tp {static_cast<unsigned int>(numThreads)};
	auto lcm = rangeLcm(tp, jobSize, std::begin(data), std::end(data));
	mngr.set(NumericArray<std::uint64_t> {lcm});
}