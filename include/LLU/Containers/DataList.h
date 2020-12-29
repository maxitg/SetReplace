/**
 * @file	DataList.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	September 01, 2018
 * @brief	Definition of templated DataStore wrapper called DataList.
 */

#ifndef LLU_CONTAINERS_DATALIST_H
#define LLU_CONTAINERS_DATALIST_H

#include <initializer_list>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "LLU/Containers/Generic/DataStore.hpp"
#include "LLU/Containers/Iterators/DataList.hpp"
#include "LLU/ErrorLog/ErrorManager.h"
#include "LLU/LibraryData.h"
#include "LLU/MArgument.h"
#include "LLU/TypedMArgument.h"

namespace LLU {

	namespace NodeType = Argument::Typed;

	/**
	 * @class   DataList
	 * @brief   Top-level wrapper over LibraryLink's DataStore.
	 * @details Designed to be strongly typed i.e. to wrap only homogeneous DataStores but by passing NodeType::Any as template parameter it will
	 *          work with arbitrary DataStores.
	 * @tparam  T - type of data stored in each node, see the \c NodeType namespace for possible node types
	 */
	template<typename T>
	class DataList : public MContainer<MArgumentType::DataStore> {
	public:
		/// Default DataList iterator is NodeIterator<T>
		using iterator = NodeIterator<T>;

		/// All DataList iterators are proxy iterators so in a way they are all const, therefore \c const_iterator is the same as \c iterator
		using const_iterator = iterator;

		/// To iterate over node values use a proxy iterator NodeValueIterator<T>
		using value_iterator = NodeValueIterator<T>;

		/// To iterate over node names use a proxy iterator NodeNameIterator
		using name_iterator = NodeNameIterator;

		/// Value of a node is of type T
		using value_type = T;

	public:
		using GenericDataList::GenericDataList; // NOLINT(modernize-use-equals-default): false positive

		/**
		 * @brief	Create DataList wrapping around an existing GenericDataList
		 * @param 	gds - GenericDataList
		 */
		explicit DataList(GenericDataList gds);

		/**
		 * @brief	Create DataList from list of values. Keys will be set to empty strings.
		 * @param 	initList - list of values to put in the DataList
		 * @note    This constructor can only be used if value_type is copyable.
		 */
		DataList(std::initializer_list<value_type> initList);

		/**
		 * @brief	Create DataList from list of keys and corresponding values.
		 * @param 	initList - list of pairs key - value to put in the DataList
		 * @note    This constructor can only be used if value_type is copyable.
		 */
		DataList(std::initializer_list<std::pair<std::string, value_type>> initList);

		/**
		 * @brief   Clone this DataList, performing a deep copy of the underlying DataStore.
		 * @note    The cloned DataStore always belongs to the library (Ownership::Library) because LibraryLink has no idea of its existence.
		 * @return  new DataList
		 */
		[[nodiscard]] DataList clone() const;

		/**
		 *	@brief Get iterator at the beginning of underlying data
		 **/
		iterator begin() const {
			return iterator {front()};
		}

		/**
		 *	@brief Get constant iterator at the beginning of underlying data
		 **/
		const_iterator cbegin() const {
			return const_iterator {begin()};
		}

		/**
		 *	@brief Get iterator after the end of underlying data
		 **/
		iterator end() const {
			return iterator {nullptr};
		}

		/**
		 *	@brief Get constant reverse iterator after the end of underlying data
		 **/
		const_iterator cend() const {
			return const_iterator {end()};
		}

		/**
		 * @brief   Get proxy iterator over node values pointing to the first node.
		 */
		value_iterator valueBegin() const {
			return value_iterator {front()};
		}

		/**
		 * @brief   Get proxy iterator over node values pointing past the last node.
		 */
		value_iterator valueEnd() const {
			return value_iterator {nullptr};
		}

		/**
		 * @brief   Get proxy iterator over node names (keys) pointing to the first node.
		 */
		name_iterator nameBegin() const {
			return name_iterator {front()};
		}

		/**
		 * @brief   Get proxy iterator over node names (keys) pointing past the last node.
		 */
		name_iterator nameEnd() const {
			return name_iterator {nullptr};
		}

		/**
		 * @brief 	Add new node to the DataList.
		 * @param 	nodeData - actual data to store in the new node
		 */
		void push_back(value_type nodeData);

		/**
		 * @brief 	Add new named node to the DataList.
		 * @param 	name - name for the new node
		 * @param 	nodeData - actual data to store in the new node
		 */
		void push_back(std::string_view name, value_type nodeData);

		/**
		 * @brief   Return a vector of DataList node values.
		 * @return  a std::vector of node values
		 */
		std::vector<T> values() const {
			return {valueBegin(), valueEnd()};
		}

		/**
		 * @brief   Return a vector of DataList node names.
		 * @return  a std::vector of node names
		 */
		std::vector<std::string> names() const {
			return {nameBegin(), nameEnd()};
		}

		/**
		 * @brief   Return a vector of DataList nodes.
		 * @return  a std::vector of nodes in the form of DataNode<T> objects
		 */
		std::vector<DataNode<T>> toVector() const {
			return {cbegin(), cend()};
		}
	};

	/* Definitions od DataList methods */

	template<typename T>
	DataList<T>::DataList(GenericDataList gds) : GenericDataList(std::move(gds)) {
		if constexpr (!std::is_same_v<T, LLU::NodeType::Any>) {
			std::for_each(GenericDataList::cbegin(), GenericDataList::cend(), [](auto node) {
				if (node.type() != Argument::WrapperIndex<T>) {
					ErrorManager::throwException(ErrorName::DLInvalidNodeType);
				}
			});
		}
	}

	template<typename T>
	DataList<T>::DataList(std::initializer_list<value_type> initList) : DataList() {
		for (auto&& elem : initList) {
			push_back(std::move(elem));
		}
	}

	template<typename T>
	DataList<T>::DataList(std::initializer_list<std::pair<std::string, value_type>> initList) : DataList() {
		for (auto&& elem : initList) {
			push_back(elem.first, std::move(elem.second));
		}
	}

	template<typename T>
	DataList<T> DataList<T>::clone() const {
		return DataList {cloneContainer(), Ownership::Library};
	}

	template<typename T>
	void DataList<T>::push_back(value_type nodeData) {
		GenericDataList::push_back(std::move(nodeData));
	}

	template<typename T>
	void DataList<T>::push_back(std::string_view name, value_type nodeData) {
		GenericDataList::push_back(name, std::move(nodeData));
	}


	namespace Detail {
		template<typename T, typename IteratorType>
		struct IteratorAdaptor {
			using iterator = IteratorType;

			explicit IteratorAdaptor(DataList<T>& d) : dl {d} {};

			iterator begin() const {
				return iterator {dl.begin()};
			}

			iterator cbegin() {
				return iterator {dl.begin()};
			}

			iterator end() const {
				return iterator {dl.end()};
			}

			iterator end() {
				return iterator {dl.end()};
			}

		private:
			DataList<T>& dl;
		};
	}  // namespace Detail

	/**
	 * @brief   Iterator adaptor for DataList that makes begin() and end() return proxy iterators for node values.
	 *          Mostly useful in range-based for loops.
	 * @tparam  T - a DataList node value type
	 */
	template<typename T>
	struct ValueAdaptor : Detail::IteratorAdaptor<T, NodeValueIterator<T>> {
		/**
		 * Create ValueAdaptor to an existing DataList
		 * @param d - DataList with nodes of type \p T
		 */
		explicit ValueAdaptor(DataList<T>& d) : Detail::IteratorAdaptor<T, NodeValueIterator<T>> {d} {};
	};

	/**
	 * @brief   Iterator adaptor for DataList that makes begin() and end() return proxy iterators for node names.
	 *          Mostly useful in range-based for loops.
	 * @tparam  T - a DataList node value type
	 */
	template<typename T>
	struct NameAdaptor : Detail::IteratorAdaptor<T, NodeNameIterator> {
		/**
		 * Create NameAdaptor to an existing DataList
		 * @param d - DataList with nodes of type \p T
		 */
		explicit NameAdaptor(DataList<T>& d) : Detail::IteratorAdaptor<T, NodeNameIterator> {d} {};
	};

}  // namespace LLU

#endif	  // LLU_CONTAINERS_DATALIST_H
