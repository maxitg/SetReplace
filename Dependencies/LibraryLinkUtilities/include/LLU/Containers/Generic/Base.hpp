/**
 * @file	Base.hpp
 * @brief   Definitions of MContainerBase and MContainer class templates.
 */

#ifndef LLU_CONTAINERS_GENERIC_BASE_HPP
#define LLU_CONTAINERS_GENERIC_BASE_HPP

#include <type_traits>

#include "LLU/ErrorLog/ErrorManager.h"
#include "LLU/LibraryData.h"
#include "LLU/MArgument.h"
#include "LLU/Utilities.hpp"

#include "LLU/Containers/Interfaces.h"

namespace LLU {

	/// An enum listing possible owners of a LibraryLink container.
	/// Ownership determines the memory management of a container.
	enum struct Ownership : uint8_t {
		LibraryLink, 	///< LibraryLink is responsible for managing the container's memory. Corresponds to Automatic and "Constant" passing.
		Library,	///< The library (LLU) is responsible for managing the container's memory. Used for Manual passing and containers created by the library.
		Shared		///< When the container is shared LLU only needs to decrease share count when it's done. Only used for arguments passed as "Shared".
	};

	/**
	 * @brief Template of the base class for all generic containers.
	 * MContainerBase stores the raw LibraryLink container and defines a common interface for all generic containers.
	 *
	 * @tparam Type - container type
	 */
	template<MArgumentType Type>
	class MContainerBase {
	public:
		/// The type of underlying LibraryLink structure (e.g. MTensor, MImage, etc.) will be called "Container"
		using Container = Argument::CType<Type>;

	public:
		/**
		 * @brief Default constructor, creates an empty wrapper.
		 */
		MContainerBase() = default;

		/**
		 * @brief Create MContainerBase from a raw container and its owner.
		 * @param c - raw LibraryLink container (MTensor, MNumericArray, etc.), passing a nullptr will trigger an exception
		 * @param owner - who manages the raw container's memory
		 */
		MContainerBase(Container c, Ownership owner) : container {c}, owner {owner} {
			if (!c) {
				ErrorManager::throwException(ErrorName::CreateFromNullError);
			}
		}

		/// Container wrappers are non-copyable, they act somewhat like unique_ptr around the raw container
		MContainerBase(const MContainerBase& mc) = delete;

		/**
		 * @brief Move-constructor steals the raw container keeping the ownership info
		 * @param mc - MContainerBase to be moved-from, it's internal container becomes nullptr
		 */
		MContainerBase(MContainerBase&& mc) noexcept : container {mc.container}, owner { mc.owner} {
			mc.container = nullptr;
		}

		/// Copy-assignment is deleted, same as copy-constructor
		MContainerBase& operator=(const MContainerBase& mc) = delete;

		/**
		 * @brief Move-assignment operator disposes of the current raw container and steals the new one keeping its ownership intact
		 * @param mc - MContainerBase to be moved-from, it's internal container becomes nullptr
		 * @return reference to this object
		 */
		MContainerBase& operator=(MContainerBase&& mc) noexcept {
			reset(mc.container, mc.owner);
			mc.container = nullptr;
			return *this;
		}

		/// Destructor takes appropriate action depending on the ownership info
		virtual ~MContainerBase() noexcept {
			if (owner == Ownership::Shared) {
				disown();
			} else if (owner == Ownership::Library) {
				free();
			}
		}

		/**
		 * @brief Get internal container
		 * @return a handle to the internal container
		 */
		Container getContainer() const noexcept {
			return container;
		}

		/**
		 * @brief Give a handle to internal container and stop owning it.
		 * Should be used with caution as it may potentially result with resource leak.
		 *
		 * @return a handle to the internal container
		 */
		Container abandonContainer() const noexcept {
			owner = Ownership::LibraryLink;
			return container;
		}

		/**
		 *   @brief Return share count of internal container, if present and 0 otherwise
		 **/
		mint shareCount() const noexcept {
			if (container) {
				return shareCountImpl();
			}
			return 0;
		}

		/**
		 * @brief   Pass the internal container as result of a LibraryLink function.
		 * @param   res - MArgument which will hold internal container of this MContainerBase
		 */
		void pass(MArgument& res) const {
			if (container) {
				passImpl(res);
			}
			// Per LibraryLink documentation: returning a Shared container does not affect the memory management, so we only need to cover
			// the case where the library owns the container. In such case the ownership is passed to the LibraryLink
			if (owner == Ownership::Library) {
				owner = Ownership::LibraryLink;
			}
		}

		/**
		 * @brief   Get ownership information
		 * @return  the owner of the internal container
		 */
		Ownership getOwner() const noexcept {
			return owner;
		}

	protected:
		/**
		 * @brief Clone the raw container, if it's present
		 * @return cloned container or nullptr if there is no internal container
		 */
		Container cloneContainer() const {
			if (container == nullptr) {
				return nullptr;
			}
			return cloneImpl();
		}

		/// Disown internal container if present
		void disown() const noexcept {
			if (!container || !LibraryData::hasLibraryData()) {
				return;
			}
			if constexpr (Type == MArgumentType::DataStore) {
				// Disowning does nothing for DataStore as it cannot be shared.
			} else if constexpr (Type == MArgumentType::Image) {
				LibraryData::ImageAPI()->MImage_disown(container);
			} else if constexpr (Type == MArgumentType::NumericArray) {
				LibraryData::NumericArrayAPI()->MNumericArray_disown(container);
			} else if constexpr (Type == MArgumentType::SparseArray) {
				LibraryData::SparseArrayAPI()->MSparseArray_disown(container);
			} else if constexpr (Type == MArgumentType::Tensor) {
				LibraryData::API()->MTensor_disown(container);
			} else {
				static_assert(alwaysFalse<Type>, "Unsupported MContainer type.");
			}
		}

		/// Free internal container if present
		void free() const noexcept {
			if (!container || !LibraryData::hasLibraryData()) {
				return;
			}
			if constexpr (Type == MArgumentType::DataStore) {
				LibraryData::DataStoreAPI()->deleteDataStore(container);
			} else if constexpr (Type == MArgumentType::Image) {
				LibraryData::ImageAPI()->MImage_free(container);
			} else if constexpr (Type == MArgumentType::NumericArray) {
				LibraryData::NumericArrayAPI()->MNumericArray_free(container);
			} else if constexpr (Type == MArgumentType::SparseArray) {
				LibraryData::SparseArrayAPI()->MSparseArray_free(container);
			} else if constexpr (Type == MArgumentType::Tensor) {
				LibraryData::API()->MTensor_free(container);
			} else {
				static_assert(alwaysFalse<Type>, "Unsupported MContainer type.");
			}
		}

		/**
		 * @brief   Set a new internal container safely disposing of the old one.
		 * @param   newCont - new internal container
		 * @param   newOwnerMode - owner of the new container
		 */
		void reset(Container newCont, Ownership newOwnerMode = Ownership::Library) noexcept {
			switch (owner) {
				case Ownership::Shared:
					disown();
					break;
				case Ownership::Library:
					free();
					break;
				case Ownership::LibraryLink: break;
			}
			owner = newOwnerMode;
			container = newCont;
		}

	private:
		/// Make a deep copy of the raw container
		virtual Container cloneImpl() const = 0;

		virtual mint shareCountImpl() const = 0;

		/**
		 * @brief   Pass the raw container as result of a library function.
		 * @param   res - MArgument that will store the result of library function
		 */
		virtual void passImpl(MArgument& res) const = 0;

		/// Raw LibraryLink container (MTensor, MImage, DataStore, etc.)
		Container container {};

		mutable Ownership owner = Ownership::Library;
	};

	/**
	 * @class   MContainer
	 * @brief   MContainer is an abstract class template for generic containers. Only specializations shall be used.
	 * @tparam  Type - container type (see MArgumentType definition)
	 */
	template<MArgumentType Type, typename std::enable_if_t<Argument::ContainerTypeQ<Type>, int> = 0>
#ifdef _WIN32
	class MContainer;	 // On Windows we cannot provide a body with static_assert because of ridiculous MSVC compiler errors (probably a bug).
#else					 // On other platforms we get a nice, compile-time error.
	class MContainer {
		static_assert(alwaysFalse<Type>, "Trying to instantiate unspecialized MContainer template.");
	};
#endif
}  // namespace LLU

#endif	  // LLU_CONTAINERS_GENERIC_BASE_HPP
