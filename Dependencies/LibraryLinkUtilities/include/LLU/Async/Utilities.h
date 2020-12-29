/**
 * @file	Utilities.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief   Set of small utility classes and functions used in the Async part of LLU.
 */
#ifndef LLU_ASYNC_UTILITIES_H
#define LLU_ASYNC_UTILITIES_H

#include <functional>
#include <future>
#include <memory>
#include <thread>
#include <vector>

namespace LLU::Async {

	/**
	 * @class FunctionWrapper
	 * @brief Wraps an arbitrary callable object (possibly binding its arguments) to be evaluated later.
	 * The callable object, when called on provided arguments, must return void.
	 */
	class FunctionWrapper {
		/// Abstract interface for type-erased callable classes
		struct TypeErasedCallableBase {
			virtual void call() = 0;
			virtual ~TypeErasedCallableBase() = default;
		};

		/**
		 * @brief   Internal structure that represents type-erased callable objects
		 * @tparam  F - any callable type (function, lambda, member function, etc)
		 */
		template<typename F>
		struct TypeErasedCallable : TypeErasedCallableBase {
			explicit TypeErasedCallable(F&& f) : callable(std::forward<F>(f)) {}

			void call() override {
				callable();
			}
			F callable;
		};

	public:
		/**
		 * @brief   Create a FunctionWrapper from any callable object by performing type-erasure
		 * @tparam  F - any callable type (function, lambda, member function, etc)
		 * @param   f - a callable object of type \p F
		 */
		template<typename F, typename = std::enable_if_t<!std::is_same_v<std::remove_cv<F>, FunctionWrapper>>>
		explicit FunctionWrapper(F&& f) : impl {std::make_unique<TypeErasedCallable<F>>(std::forward<F>(f))} {}

		/**
		 * @brief   Create a FunctionWrapper from a callable object and arguments for the call
		 * @tparam  F - any callable type (function, lambda, member function, etc)
		 * @tparam  Args - function call argument types
		 * @param   f - a callable object of type \p F
		 * @param   args - function call arguments
		 */
		template<typename F, typename... Args>
		explicit FunctionWrapper(F&& f, Args&&... args) {
			auto boundF = std::bind(std::forward<F>(f), std::forward<Args>(args)...);
			impl = std::make_unique<TypeErasedCallable<F>>(std::move(boundF));
		}

		/// @cond
		FunctionWrapper() = default;
		FunctionWrapper(FunctionWrapper&& other) noexcept = default;
		FunctionWrapper& operator=(FunctionWrapper&& other) noexcept = default;
		FunctionWrapper(const FunctionWrapper&) = delete;
		FunctionWrapper& operator=(const FunctionWrapper&) = delete;
		~FunctionWrapper() = default;
		/// @endcond

		/// Call the internal callable object
		void operator()() {
			impl->call();
		}

	private:
		/// Internal pointer to the type-erased callable object
		std::unique_ptr<TypeErasedCallableBase> impl = nullptr;
	};

	/**
	 * @class ThreadJoiner
	 * @brief A guard for a vector of threads to make sure they are joined before their destruction.
	 * The developer must ensure that the lifetime a ThreadJoiner does not exceed the lifetime of the vector it guards.
	 *
	 * @note This class may get deprecated in favor of std::jthread when LLU switches to C++20.
	 */
	class ThreadJoiner {
		std::vector<std::thread>& threads;

	public:
		/**
		 * Create a ThreadJoiner from a reference to a vector of threads
		 * @param threadsToJoin - non-const reference to a vector of threads
		 */
		explicit ThreadJoiner(std::vector<std::thread>& threadsToJoin) : threads(threadsToJoin) {}

		ThreadJoiner(const ThreadJoiner&) = delete;
		ThreadJoiner& operator=(const ThreadJoiner&) = delete;
		ThreadJoiner(ThreadJoiner&&) = delete;
		ThreadJoiner& operator=(ThreadJoiner&&) = delete;

		/// The destuctor loops over the vector of threads and joins each one after checking if it is joinable
		~ThreadJoiner() {
			for (auto& t : threads) {
				if (t.joinable()) {
					t.join();
				}
			}
		}
	};

	/**
	 * Create a std::packaged_task from a callable object and arguments to it.
	 * @tparam FunctionType - arbitrary type of a callable object
	 * @tparam Args - paramater pack with function argument types
	 * @param f - callable object
	 * @param args - arguments for a call to \p f
	 * @return a call to \p f with arguments \p args wrapped in a std::packaged_task
	 */
	template<typename FunctionType, typename... Args>
	std::packaged_task<std::invoke_result_t<FunctionType, Args...>()> getPackagedTask(FunctionType&& f, Args&&... args) {
		using result_type = std::invoke_result_t<FunctionType, Args...>;
		// NOLINTNEXTLINE(modernize-avoid-bind): perfect forwarding capture of a parameter pack in a lambda is not trivial
		auto boundF = std::bind(std::forward<FunctionType>(f), std::forward<Args>(args)...);
		return std::packaged_task<result_type()> {std::move(boundF)};
	}

	/**
	 * @class Pausable
	 * @brief Utility class for pausable task queues.
	 */
	class Pausable {
		std::atomic_bool pausedQ = false;
		std::mutex workersMutex;
		std::condition_variable pausedWorkers;
	public:

		/// This is the function worker threads will call to see if the work has been paused.
		/// If it has, they will wait on the condition variable.
		void checkPause() {
			if (pausedQ) {
				std::unique_lock lck {workersMutex};
				pausedWorkers.wait(lck, [&]() -> bool { return !pausedQ; });
			}
		}

		/// Signal to pause work
		void pause() noexcept {
			pausedQ = true;
		}

		/// Signal to resume work and notify waiting worker threads
		void resume() noexcept {
			pausedQ = false;
			pausedWorkers.notify_all();
		}
	};
} // namespace LLU::Async

#endif	  // LLU_ASYNC_UTILITIES_H