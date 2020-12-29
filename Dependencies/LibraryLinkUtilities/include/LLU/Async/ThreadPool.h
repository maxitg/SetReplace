/**
 * @file
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief   Definitions of two thread pool classes: basic with a single queue for all threads and more advanced one with local queues and work stealing.
 */

#ifndef LLU_ASYNC_THREADPOOL_H
#define LLU_ASYNC_THREADPOOL_H

#include <atomic>
#include <deque>
#include <functional>
#include <future>
#include <thread>
#include <type_traits>
#include <vector>

#include "LLU/Async/Queue.h"
#include "LLU/Async/Utilities.h"
#include "LLU/Async/WorkStealingQueue.h"

namespace LLU::Async {

	/**
	 * @brief Simple thread pool class with a single queue. Threads block on the queue if there is no work to do.
	 * @tparam Queue - any threadsafe queue class that provides push and waitPop methods
	 */
	template<typename Queue>
	class BasicThreadPool {
	public:
		/// Type of the tasks processed by the Queue
		using TaskType = typename Queue::value_type;

	public:
		/// Create a BasicThreadPool with the default number of threads (equal to the hardware concurrency)
		BasicThreadPool() : BasicThreadPool(std::thread::hardware_concurrency()) {};

		/**
		 * Create a BasicThreadPool with given number of threads
		 * @param threadCount - requested number of threads in the pool
		 */
		explicit BasicThreadPool(unsigned threadCount) : joiner(threads) {
			try {
				for (unsigned i = 0; i < threadCount; ++i) {
					threads.emplace_back(&BasicThreadPool::workerThread, this);
				}
			} catch (...) {
				done = true;
				throw;
			}
		}

		// Thread pool is non-copyable
		BasicThreadPool(const BasicThreadPool&) = delete;
		BasicThreadPool& operator=(const BasicThreadPool&) = delete;
		BasicThreadPool(BasicThreadPool&&) = delete;
		BasicThreadPool& operator=(BasicThreadPool&&) = delete;

		/**
		 * @brief   Destructor sets the "done" flag and unblocks all blocked threads by queuing a proper number of special tasks.
		 * @details Worker threads are joined in the destructor of Async::ThreadJoiner member
		 */
		~BasicThreadPool() {
			done = true;
			for ([[maybe_unused]] auto& t : threads) {
				workQueue.push(TaskType {[] {}});
			}
		}

		/**
		 * Main function of the pool which accepts tasks to be evaluated by the worker threads.
		 * A task is simply a deferred evaluation of a function call.
		 * @tparam FunctionType - type of the function to be called in a worker thread
		 * @tparam Args - argument types of the submitted task
		 * @param f - function to be called as the task
		 * @param args - argument to the function call
		 * @return a future result of calling \p f on \p args
		 */
		template<typename FunctionType, typename... Args>
		std::future<std::invoke_result_t<FunctionType, Args...>> submit(FunctionType&& f, Args&&... args) {
			auto task = Async::getPackagedTask(std::forward<FunctionType>(f), std::forward<Args>(args)...);
			auto res = task.get_future();
			workQueue.push(TaskType {std::move(task)});
			return res;
		}

		/// This is the function that each worker thread runs in a loop
		void runPendingTask() {
			TaskType task;
			workQueue.waitPop(task);
			task();
		}

	private:
		std::atomic_bool done = false;
		Queue workQueue;
		std::vector<std::thread> threads;
		Async::ThreadJoiner joiner;

		void workerThread() {
			while (!done) {
				runPendingTask();
			}
		}
	};

	/**
	 * @brief Thread pool class with support of per-thread queues and work stealing. Based on A. Williams "C++ Concurrency in Action" 2nd Edition, chapter 9.
	 * @tparam PoolQueue - any threadsafe queue class that provides push and tryPop methods
	 * @tparam LocalQueue - any threadsafe queue class that provides push, tryPop and trySteal methods
	 */
	template<typename PoolQueue, typename LocalQueue>
	class GenericThreadPool : public Async::Pausable {
	public:
		/// Type of the tasks processed by the Queue
		using TaskType = typename PoolQueue::value_type;

	public:
		/// Create a GenericThreadPool with the default number of threads (equal to the hardware concurrency)
		GenericThreadPool() : GenericThreadPool(std::thread::hardware_concurrency()) {};

		/**
		 * Create a GenericThreadPool with given number of threads
		 * @param threadCount - requested number of threads in the pool
		 */
		explicit GenericThreadPool(unsigned threadCount) : joiner(threads) {
			try {
				for (unsigned i = 0; i < threadCount; ++i) {
					queues.emplace_back(std::make_unique<LocalQueue>());
				}
				for (unsigned i = 0; i < threadCount; ++i) {
					threads.emplace_back(&GenericThreadPool::workerThread, this, i);
				}
			} catch (...) {
				done = true;
				throw;
			}
		}

		// Thread pool is non-copyable
		GenericThreadPool(const GenericThreadPool&) = delete;
		GenericThreadPool& operator=(const GenericThreadPool&) = delete;
		GenericThreadPool(GenericThreadPool&&) = delete;
		GenericThreadPool& operator=(GenericThreadPool&&) = delete;

		/**
		 * @brief   Destructor sets the "done" flag and notifies all paused threads.
		 * @details Worker threads are joined in the destructor of Async::ThreadJoiner member
		 */
		~GenericThreadPool() {
			done = true;
			resume();
		}

		/**
		 * Main function of the pool which accepts tasks to be evaluated by the worker threads.
		 * A task is simply a deferred evaluation of a function call.
		 * @tparam FunctionType - type of the function to be called in a worker thread
		 * @tparam Args - argument types of the submitted task
		 * @param f - function to be called as the task
		 * @param args - argument to the function call
		 * @return a future result of calling \p f on \p args
		 */
		template<typename FunctionType, typename... Args>
		std::future<std::invoke_result_t<FunctionType, Args...>> submit(FunctionType&& f, Args&&... args) {
			auto task = Async::getPackagedTask(std::forward<FunctionType>(f), std::forward<Args>(args)...);
			auto res = task.get_future();
			if (localWorkQueue) {
				localWorkQueue->push(TaskType {std::move(task)});
			} else {
				poolWorkQueue.push(TaskType {std::move(task)});
			}
			return res;
		}

		/// This is the function that each worker thread runs in a loop
		void runPendingTask() {
			TaskType task;
			if (popTaskFromLocalQueue(task) || popTaskFromPoolQueue(task) || popTaskFromOtherThreadQueue(task)) {
				task();
			} else {
				std::this_thread::yield();
			}
		}

	private:
		std::atomic_bool done = false;
		PoolQueue poolWorkQueue;
		std::vector<std::unique_ptr<LocalQueue>> queues;
		std::vector<std::thread> threads;
		Async::ThreadJoiner joiner;
		inline static thread_local LocalQueue* localWorkQueue = nullptr;
		inline static thread_local unsigned myIndex = 0;

		void workerThread(unsigned my_index_) {
			myIndex = my_index_;
			localWorkQueue = queues[myIndex].get();
			while (!done) {
				runPendingTask();
				checkPause();
			}
		}
		bool popTaskFromLocalQueue(TaskType& task) {
			return localWorkQueue && localWorkQueue->tryPop(task);
		}
		bool popTaskFromPoolQueue(TaskType& task) {
			return poolWorkQueue.tryPop(task);
		}
		bool popTaskFromOtherThreadQueue(TaskType& task) {
			for (unsigned i = 0; i < queues.size(); ++i) {
				unsigned const index = (myIndex + i + 1) % queues.size();
				if (queues[index]->trySteal(task)) {
					return true;
				}
			}
			return false;
		}
	};

}  // namespace LLU::Async

namespace LLU {
	/// Alias for BasicThreadPool with ThreadsafeQueue storing Async::FunctionWrappers.
	/// Good default choice for a thread pool for any paclet.
	using BasicPool = Async::BasicThreadPool<Async::ThreadsafeQueue<Async::FunctionWrapper>>;

	/// Alias for GenericThreadPool with ThreadsafeQueue and WorkStealingQueue storing Async::FunctionWrappers.
	/// Good choice for a thread pool if the tasks that will be executed involve submitting new tasks for the pool.
	using ThreadPool = Async::GenericThreadPool<Async::ThreadsafeQueue<Async::FunctionWrapper>, Async::WorkStealingQueue<std::deque<Async::FunctionWrapper>>>;
}// namespace LLU

#endif	  // LLU_ASYNC_THREADPOOL_H
