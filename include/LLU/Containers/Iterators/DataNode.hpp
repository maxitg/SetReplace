/**
 * @file	DataNode.hpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	May 06, 2020
 * @brief
 */
#ifndef LLU_CONTAINERS_ITERATORS_DATANODE_HPP
#define LLU_CONTAINERS_ITERATORS_DATANODE_HPP

#include <type_traits>

#include "LLU/Containers/Generic/DataStore.hpp"
#include "LLU/TypedMArgument.h"

namespace LLU {

	/**
	 * @class	DataNode
	 * @brief	Wrapper over DataStoreNode structure from LibraryLink.
	 */
	template<typename T>
	class DataNode {
		static constexpr bool isGeneric = std::is_same_v<T, Argument::TypedArgument>;
		static_assert(Argument::WrapperQ<T>, "DataNode type is not a valid MArgument wrapper type.");

	public:
		/**
		 * @brief 	Create DataNode from raw DataStoreNode structure
		 * @param 	dsn - raw node
		 */
		explicit DataNode(DataStoreNode dsn);

		/**
		 * @brief 	Create DataNode from raw GenericDataNode
		 * @param 	gn - generic data node
		 */
		explicit DataNode(GenericDataNode gn);

		/**
		 * @brief 	Get node value
		 * @return 	Returns a reference to node value
		 */
		T& value() {
			return nodeArg;
		}

		/**
		 * @brief 	Get node value
		 * @return 	Returns a reference to node value
		 */
		const T& value() const {
			return nodeArg;
		}

		/**
		 * @brief   Get node name
		 * @return  string_view to the node name
		 * @note    If you store the result of this function make sure it does not outlive the underlying DataStore node, otherwise make a string copy
		 */
		std::string_view name() const {
			return node.name();
		}

		/**
		 * @brief   Check if this node has a successor
		 * @return  true iff the current node is not the last one in its DataList
		 */
		bool hasNext() const {
			return static_cast<bool>(node.next());
		}

		/**
		 * @brief   Get next node as GenericDataNode (because the next node may not necessarily have value of type T)
		 * @return  GenericDataNode wrapper of next node, or empty if this is the last node
		 */
		GenericDataNode next() const {
			return node.next();
		}

		/**
		 * @brief 	Get the actual type of node value. This is useful when working on a "generic" DataList.
		 * @return	Actual type of node value
		 */
		MArgumentType type() noexcept {
			return node.type();
		}

		/**
		 * Get N-th element of DataNode in a tuple-like way. This function enables structured bindings to DataNodes.
		 * @tparam N - index (only 0 and 1 are valid)
		 * @return either the node name for N == 0 or node value for N == 1
		 */
		template <std::size_t N>
		decltype(auto) get() {
			static_assert(N < 2, "Bad structure binding attempt to a DataNode.");
			if constexpr (N == 0) {
				return name();
			} else {
				return (nodeArg);
			}
		}

	private:
		GenericDataNode node {};
		T nodeArg;
	};

	/* Definitions od DataNode methods */
	template<typename T>
	DataNode<T>::DataNode(DataStoreNode dsn) : DataNode(GenericDataNode {dsn}) {}

	template<typename T>
	DataNode<T>::DataNode(GenericDataNode gn) : node {gn} {
		if (!node) {
			ErrorManager::throwException(ErrorName::DLNullRawNode);
		}
		if constexpr (isGeneric) {
			nodeArg = std::move(node.value());
		} else{
			nodeArg = std::move(node.as<T>());
		}
	}


}/* namespace LLU */

namespace std {
	template<typename T>
	class tuple_size<LLU::DataNode<T>> : public std::integral_constant<std::size_t, 2> {};

	template<std::size_t N, typename T>
	class tuple_element<N, LLU::DataNode<T>> {
	public:
		using type = decltype(std::declval<LLU::DataNode<T>>().template get<N>());
	};
}

#endif	  // LLU_CONTAINERS_ITERATORS_DATANODE_HPP
