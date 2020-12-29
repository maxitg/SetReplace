/**
 * @file
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @brief   Definition and implementation of a thread-safe queue, taken from A. Williams "C++ Concurrency in Action" 2nd Edition, chapter 6.
 */
#ifndef LLU_ASYNC_QUEUE_H
#define LLU_ASYNC_QUEUE_H

#include <condition_variable>
#include <memory>
#include <mutex>

namespace LLU::Async {
	/**
	 * @brief   ThreadsafeQueue is a linked list of nodes which supports safe concurrent access to its head (removing elements) and tail (adding new elements).
	 * ThreadsafeQueue is described in chapter 6 of A. Williams "C++ Concurrency in Action" 2nd Edition.
	 * This implementation contains only slight modifications and minor bugfixes.
	 * @tparam  T - type of the data stored in the Queue
	 */
	template<typename T>
	class ThreadsafeQueue {
	public:
		/// Value type of queue elements
		using value_type = T;
	public:
		/**
		 * @brief   Create new empty queue.
		 */
		ThreadsafeQueue() : head(new Node), tail(head.get()) {}

		/**
		 * @brief   Get data from the queue if available.
		 * If data is not available in the queue, the calling thread will not wait.
		 * @return  Shared pointer to the data from the queue's head, nullptr if there is no data to be popped.
		 */
		std::shared_ptr<value_type> tryPop();

		/**
		 * @brief       Get data from the queue if available.
		 * If data is not available in the queue, the calling thread will not wait.
		 * @param[out]  value - reference to the data from the queue
		 * @return      True iff there was data in the queue, otherwise the out-parameter remains unchanged.
		 */
		bool tryPop(value_type& value);

		/**
		 * @brief   Get data from the queue, possibly waiting for it.
		 * @return  Shared pointer to the data from the queue's head
		 */
		std::shared_ptr<value_type> waitPop();

		/**
		 * @brief   Get data from the queue, possibly waiting for it.
		 * @param   value - reference to the data from the queue
		 */
		void waitPop(value_type& value);

		/**
		 * @brief   Push new value to the end of the queue.
		 * This operation can be performed even with other thread popping a value from the queue at the same time.
		 * @param   new_value - value to be pushed to the queue
		 */
		void push(value_type new_value);

		/**
		 * @brief   Check if the queue is empty.
		 * @return  True iff the queue is empty i.e. has no data to be popped.
		 */
		[[nodiscard]] bool empty() const;

	private:
		/// Internal structure that represents a single element of the queue
		struct Node {
			std::shared_ptr<value_type> data;
			std::unique_ptr<Node> next;
		};

		mutable std::mutex head_mutex;
		std::unique_ptr<Node> head;
		mutable std::mutex tail_mutex;
		Node* tail;
		std::condition_variable data_cond;

		const Node* getTail() const {
			std::lock_guard<std::mutex> tail_lock(tail_mutex);
			return tail;
		}

		std::unique_ptr<Node> popHead() {
			std::unique_ptr<Node> old_head = std::move(head);
			head = std::move(old_head->next);
			return old_head;
		}

		std::unique_lock<std::mutex> waitForData() {
			std::unique_lock<std::mutex> head_lock(head_mutex);
			data_cond.wait(head_lock, [&] { return head.get() != getTail(); });
			return head_lock;
		}

		std::unique_ptr<Node> waitPopHead() {
			std::unique_lock<std::mutex> head_lock(waitForData());
			return popHead();
		}

		std::unique_ptr<Node> waitPopHead(value_type& value) {
			std::unique_lock<std::mutex> head_lock(waitForData());
			value = std::move(*head->data);
			return popHead();
		}

		std::unique_ptr<Node> tryPopHead() {
			std::lock_guard<std::mutex> head_lock(head_mutex);
			if (head.get() == getTail()) {
				return std::unique_ptr<Node>();
			}
			return popHead();
		}

		std::unique_ptr<Node> tryPopHead(value_type& value) {
			std::lock_guard<std::mutex> head_lock(head_mutex);
			if (head.get() == getTail()) {
				return std::unique_ptr<Node>();
			}
			value = std::move(*head->data);
			return popHead();
		}
	};

	template<typename T>
	void ThreadsafeQueue<T>::push(T new_value) {
		std::shared_ptr<T> new_data(std::make_shared<T>(std::move(new_value)));
		std::unique_ptr<Node> p(new Node);
		{
			std::lock_guard<std::mutex> tail_lock(tail_mutex);
			tail->data = new_data;
			Node* const new_tail = p.get();
			tail->next = std::move(p);
			tail = new_tail;
		}
		data_cond.notify_one();
	}

	template<typename T>
	std::shared_ptr<T> ThreadsafeQueue<T>::waitPop() {
		std::unique_ptr<Node> const old_head = waitPopHead();
		return old_head->data;
	}

	template<typename T>
	void ThreadsafeQueue<T>::waitPop(T& value) {
		std::unique_ptr<Node> const old_head = waitPopHead(value);
	}

	template<typename T>
	std::shared_ptr<T> ThreadsafeQueue<T>::tryPop() {
		std::unique_ptr<Node> const old_head = tryPopHead();
		return old_head ? old_head->data : std::shared_ptr<T>();
	}

	template<typename T>
	bool ThreadsafeQueue<T>::tryPop(T& value) {
		std::unique_ptr<Node> const old_head = tryPopHead(value);
		return static_cast<bool>(old_head);
	}

	template<typename T>
	bool ThreadsafeQueue<T>::empty() const {
		std::lock_guard<std::mutex> head_lock(head_mutex);
		return (head.get() == getTail());
	}
}  // namespace LLU::Async
#endif	  // LLU_ASYNC_QUEUE_H
