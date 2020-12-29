/**
 * @file	PoliciesTest.cpp
 * @brief	Unit tests for passing policies and related functionality
 */

#include <LLU/ErrorLog/Logger.h>
#include <LLU/LLU.h>
#include <LLU/LibraryLinkFunctionMacro.h>

using LLU::Ownership;
using LLU::Passing;
namespace ErrorCode = LLU::ErrorCode;

std::string to_string(Ownership o) {
	switch (o) {
		case Ownership::LibraryLink:
			return "LibraryLink";
		case Ownership::Library:
			return "Library";
		case Ownership::Shared:
			return "Shared";
	}
	return "Unknown";
}

template<class Container>
bool isShared(const Container& c) noexcept {
	return c.getOwner() == Ownership::Shared;
}

template<class Container>
bool libraryOwnedQ(const Container& c) noexcept {
	return c.getOwner() == Ownership::Library;
}

template<class Container>
bool libraryLinkOwnedQ(const Container& c) noexcept {
	return c.getOwner() == Ownership::LibraryLink;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
	LLU::LibraryData::setLibraryData(libData);
	return 0;
}

LIBRARY_LINK_FUNCTION(IsOwnerAutomatic) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto img = mngr.getGenericImage(0);
	mngr.set(libraryLinkOwnedQ(img));
	return ErrorCode::NoError;
}

LIBRARY_LINK_FUNCTION(IsOwnerManual) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto t = mngr.getGenericTensor<Passing::Manual>(0);
	mngr.set(libraryOwnedQ(t));
	return ErrorCode::NoError;
}

LIBRARY_LINK_FUNCTION(IsOwnerShared) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto na = mngr.getGenericNumericArray<Passing::Shared>(0);
	mngr.set(isShared(na));
	return ErrorCode::NoError;
}

LIBRARY_LINK_FUNCTION(CloneAutomatic) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto img = mngr.getGenericImage(0);
	LLU::GenericImage clone {img.clone()};
	mngr.set(clone);
	return (libraryLinkOwnedQ(img) && libraryLinkOwnedQ(clone)) ? ErrorCode::NoError : ErrorCode::MemoryError;
}

LIBRARY_LINK_FUNCTION(CloneManual) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto t = mngr.getGenericTensor<Passing::Manual>(0);
	LLU::GenericTensor clone {t.clone()};
	LLU::Tensor<mint> tensor {std::move(t)};
	tensor[0] = -1;
	mngr.set(clone);
	// NOLINTNEXTLINE(bugprone-use-after-move): deliberate use after move for testing purposes
	return (libraryOwnedQ(t) && libraryOwnedQ(tensor) && libraryLinkOwnedQ(clone)) ? ErrorCode::NoError : ErrorCode::MemoryError;
}

LIBRARY_LINK_FUNCTION(CloneShared) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto na = mngr.getGenericNumericArray<Passing::Shared>(0);
	LLU::GenericNumericArray clone {na.clone()};
	mngr.set(clone);
	return (isShared(na) && libraryLinkOwnedQ(clone)) ? ErrorCode::NoError : ErrorCode::MemoryError;
}

LIBRARY_LINK_FUNCTION(MoveAutomatic) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto img = mngr.getGenericImage(0);
	LLU_DEBUG("Automatic arg owner: ", to_string(img.getOwner()));
	LLU::GenericImage clone = std::move(img);	// we can create Automatic container if we move from another Automatic
	LLU_DEBUG("Automatic arg owner: ", to_string(img.getOwner()), ", clone owner: ", to_string(clone.getOwner()));
	mngr.set(clone);
	LLU_DEBUG("Automatic arg owner: ", to_string(img.getOwner()), ", clone owner: ", to_string(clone.getOwner()));
	// NOLINTNEXTLINE(bugprone-use-after-move): deliberate use after move for testing purposes
	return (libraryLinkOwnedQ(img) && libraryLinkOwnedQ(clone)) ? ErrorCode::NoError : ErrorCode::MemoryError;
}

LIBRARY_LINK_FUNCTION(MoveManual) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto t = mngr.getGenericTensor<Passing::Manual>(0);
	LLU_DEBUG("Manual arg owner: ", to_string(t.getOwner()));
	LLU::Tensor<mint> tensor {std::move(t)};
	tensor[0] = -324;
	LLU::GenericTensor clone = std::move(tensor);
	LLU_DEBUG("Manual arg owner: ", to_string(t.getOwner()), ", clone owner: ", to_string(clone.getOwner()));
	mngr.set(clone);
	LLU_DEBUG("Manual arg owner: ", to_string(t.getOwner()), ", clone owner: ", to_string(clone.getOwner()));
	// NOLINTNEXTLINE(bugprone-use-after-move): deliberate use after move for testing purposes
	return (libraryOwnedQ(t) && libraryOwnedQ(tensor) && libraryLinkOwnedQ(clone)) ? ErrorCode::NoError : ErrorCode::MemoryError;
}

LIBRARY_LINK_FUNCTION(MoveShared) {
	LLU::MArgumentManager mngr {libData, Argc, Args, Res};
	auto na = mngr.getGenericNumericArray<Passing::Shared>(0);
	LLU_DEBUG("Shared arg owner: ", to_string(na.getOwner()));
	LLU::GenericNumericArray clone = std::move(na);
	LLU_DEBUG("Shared arg owner: ", to_string(na.getOwner()), ", clone owner: ", to_string(clone.getOwner()));
	mngr.set(clone);
	LLU_DEBUG("Shared arg owner: ", to_string(na.getOwner()), ", clone owner: ", to_string(clone.getOwner()));
	// NOLINTNEXTLINE(bugprone-use-after-move): deliberate use after move for testing purposes
	return (isShared(na) && isShared(clone)) ? ErrorCode::NoError : ErrorCode::MemoryError;
}