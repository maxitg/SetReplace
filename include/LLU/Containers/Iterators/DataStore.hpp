/**
 * @file	DataStore.hpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	May 04, 2020
 * @brief
 */
#ifndef LLU_CONTAINERS_ITERATORS_DATASTORE_HPP
#define LLU_CONTAINERS_ITERATORS_DATASTORE_HPP

#include <iterator>

#include "LLU/LibraryData.h"
#include "LLU/MArgument.h"
#include "LLU/TypedMArgument.h"

namespace LLU {

	/**
	 * @struct  GenericDataNode
	 * @brief   Basic wrapper over DataStoreNode, provides class-like interface and conversion of the underlying value from MArgument to TypedArgument.
	 */
	struct GenericDataNode {
		/// Raw DataStore node
		DataStoreNode node;

		/**
		 * Get GenericDataNode wrapper over the next node
		 * @return next node wrapped in GenericDataNode
		 */
		GenericDataNode next() const noexcept;

		/**
		 * Get type of the node value
		 * @return type of the node value
		 */
		MArgumentType type() const noexcept;

		/**
		 * Get node name
		 * @return string view over the name of the node
		 */
		std::string_view name() const noexcept;

		/**
		 * Get value of the node as the variant type
		 * @return TypedArgument variant holding the value of the node
		 */
		[[nodiscard]] Argument::TypedArgument value() const;

		// defined in Containers/Generic/DataStore.hpp because the definition of GenericDataList must be available
		/**
		 * Get node value if it is of type T, otherwise throw an exception.
		 * @tparam T - any type from LLU::NodeType namespace
		 * @return node value of type T
		 */
		template<typename T>
		T as() const;

		/**
		 * Bool conversion operator
		 * @return true iff the node is not null
		 */
		explicit operator bool() const;

		/// Member of pointer operator, used by DataList iterators
		GenericDataNode* operator->() {
			return this;
		}
	};

	/**
	 * @class   DataStoreIterator
	 * @brief   Proxy input iterator over DataStoreNodes, when dereferenced yields GenericDataNode proxy objects.
	 */
	class DataStoreIterator {
		DataStoreNode node;

	public:
		/// This iterator returns proxy objects of type GenericDataNode
		using value_type = GenericDataNode;

		/// DataStoreIterator is a proxy iterator and so the reference type is the same as value_type
		using reference = value_type;

		/// As with all proxy iterators, DataStoreIterator is only an input iterator
		using iterator_category = std::input_iterator_tag;

		/// DataStoreIterator is a proxy iterator and so the pointer type is the same as value_type
		using pointer = value_type;

		/// Provide difference_type as required for input iterators
		using difference_type = mint;

		/// Create a DataStoreIterator pointing to a given node
		explicit DataStoreIterator(DataStoreNode n) : node{n} {}

		/**
		 * Get proxy object of the current node
		 * @return proxy object of current node
		 */
		reference operator*() const {
			return reference {node};
		}

		/**
		 * Get proxy object of the current node
		 * @return proxy object of current node
		 */
		pointer operator->() const {
			return pointer {node};
		}

		/**
		 * Pre-increment operator
		 * @return this
		 */
		DataStoreIterator& operator++() {
			node = LLU::LibraryData::DataStoreAPI()->DataStoreNode_getNextNode(node);
			return *this;
		}

		/**
		 * Post-increment operator
		 * @return "old" copy of the iterator object
		 */
		DataStoreIterator operator++(int) {
			DataStoreIterator tmp {node};
			++(*this);
			return tmp;
		}

		/**
		 * "Equal to" operator for DataStoreIterators
		 * @param lhs - a DataStoreIterator
		 * @param rhs - a DataStoreIterator
		 * @return true iff both iterators point to the same node
		 */
		friend bool operator==(const DataStoreIterator& lhs, const DataStoreIterator& rhs) {
			return lhs.node == rhs.node;
		}

		/**
		 * "Not equal to" operator for DataStoreIterators
		 * @param lhs - a DataStoreIterator
		 * @param rhs - a DataStoreIterator
		 * @return false iff both iterators point to the same node
		 */
		friend bool operator!=(const DataStoreIterator& lhs, const DataStoreIterator& rhs) {
			return !(lhs == rhs);
		}
	};
}  // namespace LLU

#endif	  // LLU_CONTAINERS_ITERATORS_DATASTORE_HPP
