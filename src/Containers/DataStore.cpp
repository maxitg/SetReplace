/**
 * @file	DataStore.cpp
 * @author	Rafal Chojna <rafalc@wolfram.com>
 * @date	April 28, 2020
 * @brief
 */

#include "LLU/Containers/Generic/DataStore.hpp"

namespace LLU {

	GenericDataNode GenericDataNode::next() const noexcept {
		return {LLU::LibraryData::DataStoreAPI()->DataStoreNode_getNextNode(node)};
	}

	MArgumentType GenericDataNode::type() const noexcept {
		return static_cast<MArgumentType>(LLU::LibraryData::DataStoreAPI()->DataStoreNode_getDataType(node));
	}

	std::string_view GenericDataNode::name() const noexcept {
		char* rawName = nullptr;
		LibraryData::DataStoreAPI()->DataStoreNode_getName(node, &rawName);
		return rawName ? std::string_view {rawName} : std::string_view {""};
	}

	Argument::TypedArgument GenericDataNode::value() const {
		MArgument m;
		if (LibraryData::DataStoreAPI()->DataStoreNode_getData(node, &m) != 0) {
			ErrorManager::throwException(ErrorName::DLGetNodeDataError);
		}
		return Argument::fromMArgument(m, type());
	}

	GenericDataNode::operator bool() const {
		return node != nullptr;
	}

	MContainer<MArgumentType::DataStore>::MContainer(Container c, Ownership owner) : MContainerBase {c, owner} {
		if (owner == Ownership::Shared) {
			ErrorManager::throwException(ErrorName::DLSharedDataStore);
		}
	}

	void MContainer<MArgumentType::DataStore>::push_back(std::string_view name, const Argument::Typed::Any& node) {
		switch (static_cast<MArgumentType>(node.index())) {
			case MArgumentType::MArgument: ErrorManager::throwException(ErrorName::DLInvalidNodeType);
			case MArgumentType::Boolean:
				PrimitiveWrapper<MArgumentType::Boolean>::addDataStoreNode(getContainer(), name, static_cast<mbool>(*std::get_if<bool>(&node)));
				break;
			case MArgumentType::Integer: PrimitiveWrapper<MArgumentType::Integer>::addDataStoreNode(getContainer(), name, *std::get_if<mint>(&node)); break;
			case MArgumentType::Real: PrimitiveWrapper<MArgumentType::Real>::addDataStoreNode(getContainer(), name, *std::get_if<double>(&node)); break;
			case MArgumentType::Complex: {
				auto c = *std::get_if<std::complex<double>>(&node);
				mcomplex mc {c.real(), c.imag()};
				PrimitiveWrapper<MArgumentType::Complex>::addDataStoreNode(getContainer(), name, mc);
			} break;
			case MArgumentType::Tensor:
				PrimitiveWrapper<MArgumentType::Tensor>::addDataStoreNode(getContainer(), name, std::get_if<GenericTensor>(&node)->abandonContainer());
				break;
			case MArgumentType::SparseArray:
				PrimitiveWrapper<MArgumentType::SparseArray>::addDataStoreNode(getContainer(), name, *std::get_if<MSparseArray>(&node));
				break;
			case MArgumentType::NumericArray:
				PrimitiveWrapper<MArgumentType::NumericArray>::addDataStoreNode(getContainer(), name,
																				std::get_if<GenericNumericArray>(&node)->abandonContainer());
				break;
			case MArgumentType::Image:
				PrimitiveWrapper<MArgumentType::Image>::addDataStoreNode(getContainer(), name, std::get_if<GenericImage>(&node)->abandonContainer());
				break;
			case MArgumentType::UTF8String: {
				const auto* data = std::get_if<std::string_view>(&node)->data();
				// NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast): required by DataStore API
				PrimitiveWrapper<MArgumentType::UTF8String>::addDataStoreNode(getContainer(), name, const_cast<char*>(data));
			} break;
			case MArgumentType::DataStore:
				PrimitiveWrapper<MArgumentType::DataStore>::addDataStoreNode(getContainer(), name, std::get_if<GenericDataList>(&node)->abandonContainer());
				break;
		}
	}

	void MContainer<MArgumentType::DataStore>::push_back(const Argument::Typed::Any& node) {
		switch (static_cast<MArgumentType>(node.index())) {
			case MArgumentType::MArgument: ErrorManager::throwException(ErrorName::DLInvalidNodeType);
			case MArgumentType::Boolean:
				PrimitiveWrapper<MArgumentType::Boolean>::addDataStoreNode(getContainer(), static_cast<mbool>(*std::get_if<bool>(&node)));
				break;
			case MArgumentType::Integer: PrimitiveWrapper<MArgumentType::Integer>::addDataStoreNode(getContainer(), *std::get_if<mint>(&node)); break;
			case MArgumentType::Real: PrimitiveWrapper<MArgumentType::Real>::addDataStoreNode(getContainer(), *std::get_if<double>(&node)); break;
			case MArgumentType::Complex: {
				auto c = *std::get_if<std::complex<double>>(&node);
				mcomplex mc {c.real(), c.imag()};
				PrimitiveWrapper<MArgumentType::Complex>::addDataStoreNode(getContainer(), mc);
			} break;
			case MArgumentType::Tensor:
				PrimitiveWrapper<MArgumentType::Tensor>::addDataStoreNode(getContainer(), std::get_if<GenericTensor>(&node)->abandonContainer());
				break;
			case MArgumentType::SparseArray:
				PrimitiveWrapper<MArgumentType::SparseArray>::addDataStoreNode(getContainer(), *std::get_if<MSparseArray>(&node));
				break;
			case MArgumentType::NumericArray:
				PrimitiveWrapper<MArgumentType::NumericArray>::addDataStoreNode(getContainer(), std::get_if<GenericNumericArray>(&node)->abandonContainer());
				break;
			case MArgumentType::Image:
				PrimitiveWrapper<MArgumentType::Image>::addDataStoreNode(getContainer(), std::get_if<GenericImage>(&node)->abandonContainer());
				break;
			case MArgumentType::UTF8String: {
				const auto* data = std::get_if<std::string_view>(&node)->data();
				// NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast): required by DataStore API
				PrimitiveWrapper<MArgumentType::UTF8String>::addDataStoreNode(getContainer(), const_cast<char*>(data));
			} break;
			case MArgumentType::DataStore:
				PrimitiveWrapper<MArgumentType::DataStore>::addDataStoreNode(getContainer(), std::get_if<GenericDataList>(&node)->abandonContainer());
				break;
		}
	}
}	 // namespace LLU