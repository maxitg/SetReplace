/**
 * @file	DataList.hpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	September 07, 2018
 * @brief	Special iterators for DataLists. Iteration over keys, values, reversed iteration.
 */
#ifndef LLU_CONTAINERS_ITERATORS_DATALIST_HPP
#define LLU_CONTAINERS_ITERATORS_DATALIST_HPP

#include <iterator>
#include <list>
#include <string>

#include "LLU/Containers/Iterators/DataNode.hpp"
#include "LLU/Containers/Iterators/DataStore.hpp"
#include "LLU/MArgument.h"

namespace LLU {

	namespace Detail {
		struct DataListIteratorPrimitive {
			using iterator_category = std::input_iterator_tag;
			using pointer = void*;
			using difference_type = mint;

			GenericDataNode node;

			explicit DataListIteratorPrimitive(DataStoreNode n) : node{n} {}

			explicit DataListIteratorPrimitive(const DataStoreIterator& it) : node{*it} {}

			friend bool operator==(const DataListIteratorPrimitive& lhs, const DataListIteratorPrimitive& rhs) {
				return lhs.node.node == rhs.node.node;
			}
			friend bool operator!=(const DataListIteratorPrimitive& lhs, const DataListIteratorPrimitive& rhs) {
				return !(lhs == rhs);
			}
		};
	}  // namespace Detail

	/**
	 * @brief   Simple proxy input iterator that goes over a DataStore and returns proxy DataNodes when dereferenced
	 * @tparam  T - data node type, see LLU::NodeType namespace for supported node types
	 */
	template<typename T>
	struct NodeIterator : Detail::DataListIteratorPrimitive {
		/// This iterator iterates over values of type DataNode<T>
		using value_type = DataNode<T>;

		/// NodeIterator is a proxy iterator and so the reference type is the same as value_type
		using reference = value_type;

		using DataListIteratorPrimitive::DataListIteratorPrimitive;

		/**
		 * Get current proxy DataNode
		 * @return proxy object for the currently pointed to node
		 */
		reference operator*() const {
			return reference {node};
		}

		/**
		 * Pre-increment operator
		 * @return this
		 */
		NodeIterator& operator++() {
			node = node.next();
			return *this;
		}

		/**
		 * Post-increment operator
		 * @return "old" copy of the iterator object
		 */
		NodeIterator operator++(int) {
			NodeIterator tmp {node};
			++(*this);
			return tmp;
		}
	};

	/**
	 * @brief   Simple proxy input iterator that goes over a DataStore and returns node names when dereferenced
	 * @tparam  T - data node type, see LLU::NodeType namespace for supported node types
	 */
	struct NodeNameIterator : Detail::DataListIteratorPrimitive {

		/// This iterator iterates over node names which are represented by std::string_view
		using value_type = std::string_view;

		/// NodeIterator is a proxy iterator and so the reference type is the same as value_type
		using reference = value_type;

		using DataListIteratorPrimitive::DataListIteratorPrimitive;

		/**
		 * Create NodeNameIterator pointing to the same node as given NodeIterator<T>
		 * @tparam  T - any type. It will be discarded as node names are always strings
		 * @param   it - NodeIterator<T> from which a new NodeNameIterator will be created
		 */
		template<typename T>
		explicit NodeNameIterator(const NodeIterator<T>& it) : DataListIteratorPrimitive {it} {}

		/**
		 * Get name of the currently pointed to node
		 * @return proxy object with the name of the currently pointed to node
		 */
		reference operator*() const {
			return node.name();
		}

		/**
		 * Pre-increment operator
		 * @return this
		 */
		NodeNameIterator& operator++() {
			node = node.next();
			return *this;
		}

		/**
		 * Post-increment operator
		 * @return "old" copy of the iterator object
		 */
		NodeNameIterator operator++(int) {
			NodeNameIterator tmp {node.node};
			++(*this);
			return tmp;
		}
	};

	/**
	 * @brief   Simple proxy input iterator that goes over a DataStore and returns node values of requested type when dereferenced
	 * @tparam  T - data node type, see LLU::NodeType namespace for supported node types
	 */
	template<typename T>
	struct NodeValueIterator : Detail::DataListIteratorPrimitive {
		/// This iterator iterates over node values of type T
		using value_type = T;

		/// NodeValueIterator is a proxy iterator and so the reference type is the same as value_type
		using reference = value_type;

		using DataListIteratorPrimitive::DataListIteratorPrimitive;

		/**
		 * Create NodeValueIterator pointing to the same node as given NodeIterator<T>
		 * @param it - NodeIterator<T> from which a new NodeValueIterator will be created
		 */
		explicit NodeValueIterator(const NodeIterator<T>& it) : DataListIteratorPrimitive {it} {}

		/**
		 * Get value of the currently pointed to node
		 * Generic node values will be converted to T if it is their actual type or an exception will be throws otherwise
		 * @return proxy object with the value of the currently pointed to node
		 */
		reference operator*() const {
			if constexpr (std::is_same_v<T, Argument::Typed::Any>) {
				return  node.value();
			} else {
				return as<T>();
			}
		}

		/**
		 * Pre-increment operator
		 * @return this
		 */
		NodeValueIterator& operator++() {
			node = node.next();
			return *this;
		}

		/**
		 * Post-increment operator
		 * @return "old" copy of the iterator object
		 */
		NodeValueIterator operator++(int) {
			NodeValueIterator tmp {node.node};
			++(*this);
			return tmp;
		}

		/**
		 * Get current node value if it actually is of type U. Only makes sense for nodes of type LLU::NodeType::Any.
		 * @tparam U - any type from LLU::NodeType namespace
		 * @return current node value of type U
		 */
		template<typename U>
		U as() const {
			auto v = node.value();
			auto* ptr = std::get_if<U>(std::addressof(v));
			if (!ptr) {
				ErrorManager::throwException(ErrorName::DLInvalidNodeType);
			}
			return std::move(*ptr);
		}
	};

}	 // namespace LLU

#endif	  // LLU_CONTAINERS_ITERATORS_DATALIST_HPP
