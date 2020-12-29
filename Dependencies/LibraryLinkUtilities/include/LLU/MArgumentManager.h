/**
 * @file	MArgumentManager.h
 * @author	Rafal Chojna <rafalc@wolfram.com>
 *
 * @brief	Definition of MArgumentManager class
 *
 */

#ifndef LLU_MARGUMENTMANAGER_H
#define LLU_MARGUMENTMANAGER_H

#include <complex>
#include <cstdint>
#include <limits>
#include <memory>
#include <string>
#include <type_traits>
#include <utility>
#include <vector>

#include "LLU/Containers/DataList.h"
#include "LLU/Containers/Image.h"
#include "LLU/Containers/NumericArray.h"
#include "LLU/Containers/Tensor.h"
#include "LLU/ErrorLog/ErrorManager.h"
#include "LLU/LibraryData.h"
#include "LLU/MArgument.h"
#include "LLU/ManagedExpression.hpp"
#include "LLU/ProgressMonitor.h"

namespace LLU {

	/**
	 * @brief   Enumerated type representing different modes in which a container can be passed from LibraryLink to the library
	 * @see     <https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage.html#97446640>
	 */
	enum class Passing {
		Automatic,
		Constant,
		Manual,
		Shared
	};

	/**
	 * @class	MArgumentManager
	 * @brief	Manages arguments exchanged between the paclet C++ code and LibraryLink interface.
	 *
	 * MArgumentManager provides a safe way to access MArguments received from LibraryLink and takes care of memory management both for in- and out- arguments.
	 * Using MArgumentManager one can perform generic operations on NumericArrays, Tensors and Images independent of their data type.
	 **/
	class MArgumentManager {
	public:
		/// Size type for indexing the list of arguments that MArgumentManager manages.
		using size_type = std::size_t;

	public:
		/**
		 *   @brief         Constructor
		 *   @param[in]     Argc - number of MArguments provided
		 *   @param[in]     Args - MArguments provided
		 *   @param[in]		Res - reference to output MArgument
		 **/
		MArgumentManager(mint Argc, MArgument* Args, MArgument& Res);

		/**
		 *   @brief         Constructor
		 *   @param[in]     ld - library data
		 *   @param[in]     Argc - number of MArguments provided
		 *   @param[in]     Args - MArguments provided
		 *   @param[in]		Res - reference to output MArgument
		 **/
		MArgumentManager(WolframLibraryData ld, mint Argc, MArgument* Args, MArgument& Res);

		/************************************ MArgument "getters" ************************************/

		/**
		 *   @brief         Get MArgument of type \b mbool at position \c index
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MArgument of type \b bool at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		bool getBoolean(size_type index) const;

		/**
		 *   @brief         Get MArgument of type \b mreal at position \c index
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MArgument of type \b double at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		double getReal(size_type index) const;

		/**
		 *   @brief         Get MArgument of type \b mint at position \c index with extra static_cast if needed
		 *   @tparam		T - integral type to convert \b mint to
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MArgument value at position \c index converted to \b T
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		template<typename T>
		T getInteger(size_type index) const;

		/**
		 *   @brief         Get MArgument of type \b mcomplex at position \c index
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MArgument value at position \c index converted to \b std::complex<double>
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		std::complex<double> getComplex(size_type index) const;

		/**
		 *   @brief         Get value of MArgument of type \b "UTF8String" at position \c index
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       C-string which was received from LibraryLink
		 *   @throws        LLErrorCode::MArgumentIndexError - if \c index is out-of-bounds
		 *
		 *   @note			MArgumentManager is responsible for disowning string arguments. Do not call free() or delete() on resulting pointer.
		 **/
		char* getCString(size_type index) const;

		/**
		 *   @brief         Get value of MArgument of type \b "UTF8String" at position \c index
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       \b std::string which is created from MArgument at position \c index
		 *   @throws        LLErrorCode::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		std::string getString(size_type index) const;

		/**
		 *   @brief         Get MArgument of type MNumericArray at position \p index and wrap it into NumericArray
		 *   @tparam		T - type of data stored in NumericArray
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       NumericArray wrapper of MArgument at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @see			NumericArray<T>::NumericArray(const MNumericArray);
		 **/
		template<typename T, Passing Mode = Passing::Automatic>
		NumericArray<T> getNumericArray(size_type index) const;

		/**
		 *	@brief		Get MArgument of type MNumericArray at position \p index and wrap it into generic MContainer wrapper
		 * 	@tparam 	Mode - passing mode to be used
		 * 	@param 		index - position of desired MArgument in \c Args
		 * 	@return		MContainer wrapper of MNumericArray with given passing mode
		 */
		template<Passing Mode = Passing::Automatic>
		GenericNumericArray getGenericNumericArray(size_type index) const;

		/**
		 *   @brief         Get MArgument of type MNumericArray at position \c index
		 *   @warning       Use of this function is discouraged. Use getNumericArray instead, if possible.
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MArgument at position \c index interpreted as MNumericArray
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		MNumericArray getMNumericArray(size_type index) const;

		/**
		 *   @brief         Get MArgument of type MTensor at position \p index and wrap it into Tensor object
		 *   @tparam		T - type of data stored in Tensor
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       Tensor wrapper of MArgument at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @see			Tensor<T>::Tensor(const MTensor);
		 **/
		template<typename T, Passing Mode = Passing::Automatic>
		Tensor<T> getTensor(size_type index) const;

		/**
		 *	@brief		Get MArgument of type MTensor at position \p index and wrap it into generic MContainer wrapper
		 * 	@tparam 	Mode - passing mode to be used
		 * 	@param 		index - position of desired MArgument in \c Args
		 * 	@return		MContainer wrapper of MTensor with given passing mode
		 */
		template<Passing Mode = Passing::Automatic>
		GenericTensor getGenericTensor(size_type index) const;

		/**
		 *   @brief         Get MArgument of type MTensor at position \c index.
		 *   @warning       Use of this function is discouraged. Use getTensor instead, if possible.
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MTensor of MArgument at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		MTensor getMTensor(size_type index) const;

		/**
		 *   @brief         Get MArgument of type MImage at position \p index and wrap it into Image object
		 *   @tparam		T - type of data stored in Image
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       Image wrapper of MArgument at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @see			Image<T>::Image(const MImage ra);
		 **/
		template<typename T, Passing Mode = Passing::Automatic>
		Image<T> getImage(size_type index) const;

		/**
		 *	@brief		Get MArgument of type MImage at position \p index and wrap it into generic MContainer wrapper
		 * 	@tparam 	Mode - passing mode to be used
		 * 	@param 		index - position of desired MArgument in \c Args
		 * 	@return		MContainer wrapper of MImage with given passing mode
		 */
		template<Passing Mode = Passing::Automatic>
		GenericImage getGenericImage(size_type index) const;

		/**
		 *   @brief         Get MArgument of type MImage at position \c index.
		 *   @warning       Use of this function is discouraged. Use getImage instead, if possible.
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MImage of MArgument at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		MImage getMImage(size_type index) const;

		/**
		 *   @brief         Get DataStore with all nodes of the same type from MArgument at position \c index
		 *   @tparam		T - type of data stored in each node of DataStore, it T is MArgumentType::MArgument it will accept any node
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       DataList wrapper of MArgument at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @see			DataList<T>::DataList(DataStore ds);
		 **/
		template<typename T, Passing Mode = Passing::Automatic>
		DataList<T> getDataList(size_type index) const;

		/**
		 *	@brief		Get MArgument of type DataStore at position \p index and wrap it into generic MContainer wrapper
		 * 	@tparam 	Mode - passing mode to be used
		 * 	@param 		index - position of desired MArgument in \c Args
		 * 	@return		MContainer wrapper of DataStore with given passing mode
		 */
		template<Passing Mode = Passing::Automatic>
		GenericDataList getGenericDataList(size_type index) const;

		/**
		 *   @brief         Get MArgument of type DataStore at position \c index.
		 *   @warning       Use of this function is discouraged. Use getDataList instead.
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       DataStore of MArgument at position \c index
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		DataStore getDataStore(size_type index) const;

		/**
		 * @brief   Get a reference to an instance of Managed Expression that was sent from Wolfram Language as argument to a library function
		 * @tparam  ManagedExpr - registered Managed Expression class
		 * @tparam  DynamicType - actual type of Managed Expression, this must be ManagedExpr or its subclass
		 * @param   index - position of desired argument in \c Args
		 * @param   store - Managed Expression store that manages expressions of type ManagedExpr
		 * @return  a reference to the Managed Expression
		 */
		template<class ManagedExpr, class DynamicType = ManagedExpr>
		DynamicType& getManagedExpression(size_type index, ManagedExpressionStore<ManagedExpr>& store) const;

		/**
		 * @brief   Get a shared pointer to an instance of Managed Expression that was sent from Wolfram Language as argument to a library function
		 * @tparam  ManagedExpr - registered Managed Expression class
		 * @tparam  DynamicType - actual type of Managed Expression, this must be ManagedExpr or its subclass
		 * @param   index - position of desired argument in \c Args
		 * @param   store - Managed Expression store that manages expressions of type ManagedExpr
		 * @return  a shared pointer to the Managed Expression
		 */
		template<class ManagedExpr, class DynamicType = ManagedExpr>
		std::shared_ptr<DynamicType> getManagedExpressionPtr(size_type index, ManagedExpressionStore<ManagedExpr>& store) const;

		/************************************ MArgument generic "getters" ************************************/

		/**
		 * @brief   Helper struct to "attach" a passing mode to container type when passing it as template argument to MArgumentManager::getTuple
		 * @tparam  Container - any generic or strongly typed container wrapper type (e.g. GenericImage, Tensor<mint>, etc.)
		 * @tparam  Mode - passing mode for the container
		 */
		template<class Container, Passing Mode>
		struct Managed {};

	private:
		template<typename T>
		struct RequestedTypeImpl {
			using type = T;
		};

		template<class Container, Passing P>
		struct RequestedTypeImpl<Managed<Container, P>> {
			using type = Container;
		};

	public:
		/// RequestedType<T> is usually just T and is used as return type of MArgumentManager::get(size_type)
		template<typename T>
		using RequestedType = typename RequestedTypeImpl<T>::type;

		/**
		 * @brief   Extract library function argument at given index and convert it from MArgument to a desired type.
		 * @tparam  T - any type, for types not supported by default developers may specialize this function template
		 * @param   index - position of desired argument in \c Args
		 * @return  a value of type T created from the specified input argument
		 */
		template<typename T>
		RequestedType<T> get(size_type index) const {
			if constexpr (std::is_integral_v<T>) {
				return getInteger<T>(index);
			} else {
				return Getter<std::remove_cv_t<T>>::get(*this, index);
			}
		}

		/**
		 * @brief   Extract arguments from the Manager and return them as values of given types.
		 * @tparam  ArgTypes - types that determine how each extracted argument will be returned
		 * @return  a tuple of function arguments
		 */
		template<typename... ArgTypes>
		std::tuple<RequestedType<ArgTypes>...> getTuple(size_type index = 0) const {
			const auto indices = getOffsets(index, std::array<size_type, sizeof...(ArgTypes)> {getArgSlotCount<std::remove_cv_t<ArgTypes>>()...});
			return MArgPackGetter<ArgTypes...>::template getImpl(*this, indices, std::index_sequence_for<ArgTypes...>{});
		}

		/**
		 * @brief   Extract arguments from the Manager at given positions and return them as values of given types.
		 * @tparam  ArgTypes - types that determine how each extracted argument will be returned
		 * @param   indices - position of desired arguments, need not be sorted, may contain repeated values
		 * @return  a tuple of function arguments
		 */
		template<typename... ArgTypes>
		std::tuple<RequestedType<ArgTypes>...> getTuple(std::array<size_type, sizeof...(ArgTypes)> indices) const {
			return MArgPackGetter<ArgTypes...>::template getImpl(*this, indices, std::index_sequence_for<ArgTypes...>{});
		}

		/************************************ MArgument "setters" ************************************/

		/**
		 *   @brief         Set \c result as output MArgument
		 *   @param[in]     result - boolean value to be returned to LibraryLink
		 **/
		void setBoolean(bool result) noexcept;

		/**
		 *   @brief         Set \c result as output MArgument
		 *   @param[in]     result - value of type \b double to be returned to LibraryLink
		 **/
		void setReal(double result) noexcept;

		/**
		 *   @brief         Set \c result as output MArgument
		 *   @param[in]     result - value of type \b mint to be returned to LibraryLink
		 *   @warning		\c result will be implicitly casted to \b mint with no overflow check
		 **/
		void setInteger(mint result) noexcept;

		/**
		 *   @brief         Set \c result as output MArgument and check for overflow
		 *   @tparam		T - integral type to be casted to \b mint
		 *   @param[in]     result - value to be returned to LibraryLink
		 *   @return        true iff overflow occurred and the value had to be clipped
		 **/
		template<typename T>
		bool setMintAndCheck(T result) noexcept;

		/**
		 *   @brief         Set \c c as output MArgument
		 *   @param[in]     c - value of type \b std::complex<double> to be returned to LibraryLink
		 **/
		void setComplex(std::complex<double> c) noexcept;

		/**
		 *   @brief         Set \c str as output MArgument
		 *   @param[in]     str - reference to \b std::string to be returned to LibraryLink
		 **/
		void setString(const std::string& str);

		///  @overload
		void setString(const char* str);

		///  @overload
		void setString(std::string&& str);

		/**
		 *   @brief         Set MNumericArray wrapped by \c na as output MArgument
		 *   @tparam		T - NumericArray data type
		 *   @param[in]     na - reference to NumericArray which should pass its internal MNumericArray to LibraryLink
		 **/
		template<typename T>
		void setNumericArray(const NumericArray<T>& na);

		/**
		 *   @brief         Set MNumericArray as output MArgument
		 *   @param[in]     na - MNumericArray to be passed to LibraryLink
		 **/
		void setMNumericArray(MNumericArray na);

		/**
		 *   @brief         Set MTensor wrapped by \c ten as output MArgument
		 *   @tparam		T - Tensor data type
		 *   @param[in]     ten - reference to Tensor which should pass its internal MTensor to LibraryLink
		 **/
		template<typename T>
		void setTensor(const Tensor<T>& ten);

		/**
		 *   @brief         Set MTensor as output MArgument
		 *   @param[in]     t - MTensor to be passed to LibraryLink
		 **/
		void setMTensor(MTensor t);

		/**
		 *   @brief         Set MImage wrapped by \c im as output MArgument
		 *   @tparam		T - Image data type
		 *   @param[in]     im - reference to Image which should pass its internal MImage to LibraryLink
		 **/
		template<typename T>
		void setImage(const Image<T>& im);

		/**
		 *   @brief         Set MImage as output MArgument
		 *   @param[in]     im - MImage to be passed to LibraryLink
		 **/
		void setMImage(MImage im);

		/**
		 *   @brief         Set DataStore wrapped in DataList \c ds as output MArgument
		 *   @tparam		T - type of data stored in each node of DataStore
		 *   @param[in]     ds - const reference to DataList which should pass its internal DataStore to LibraryLink
		 **/
		template<typename T>
		void setDataList(const DataList<T>& ds);

		/**
		 *   @brief         Set DataStore as output MArgument
		 *   @param[in]     ds - DataStore to be passed to LibraryLink
		 **/
		void setDataStore(DataStore ds);

		/**
		 *   @brief         Set MSparseArray as output MArgument
		 *   @param[in]     sa - MSparseArray to be passed to LibraryLink
		 **/
		void setSparseArray(MSparseArray sa);

		/************************************ generic setters ************************************/

		/// @copydoc setBoolean
		void set(bool result) noexcept {
			setBoolean(result);
		}

		/// @copydoc setReal
		void set(double result) noexcept {
			setReal(result);
		}

		/// @copydoc setInteger
		void set(mint result) noexcept {
			setInteger(result);
		}

		/// @copydoc setComplex
		void set(std::complex<double> c) noexcept {
			setComplex(c);
		}

		/// @copydoc setString
		void set(const std::string& str) {
			setString(str);
		}

		/// @copydoc setString
		void set(const char* str) {
			setString(str);
		}

		/// @copydoc setString
		void set(std::string&& str) {
			setString(std::move(str));
		}

		/// @copydoc setNumericArray
		template<typename T>
		void set(const NumericArray<T>& na) {
			setNumericArray(na);
		}

		/**
		 *  Set MNumericArray wrapped by \c na as output MArgument
		 *  @param[in]  na - reference to generic NumericArray which should pass its internal MNumericArray to LibraryLink
		 */
		void set(const GenericNumericArray& na) {
			na.pass(res);
		}

		/// @copydoc setTensor
		template<typename T>
		void set(const Tensor<T>& ten) {
			setTensor(ten);
		}

		/**
		 *  Set MTensor wrapped by \c t as output MArgument
		 *  @param[in]  t - reference to generic Tensor which should pass its internal MTensor to LibraryLink
		 */
		void set(const GenericTensor& t) {
			t.pass(res);
		}

		/// @copydoc setImage
		template<typename T>
		void set(const Image<T>& im) {
			setImage(im);
		}

		/**
		 *  Set MImage wrapped by \c im as output MArgument
		 *  @param[in]  im - reference to generic Image which should pass its internal MImage to LibraryLink
		 */
		void set(const GenericImage& im) {
			im.pass(res);
		}

		/// @copydoc setDataList
		template<typename T>
		void set(const DataList<T>& ds) {
			setDataList(ds);
		}

		/**
		 *  Set DataStore wrapped by \c ds as output MArgument
		 *  @param[in]  ds - reference to generic DataStore which should pass its internal DataStore to LibraryLink
		 */
		void set(const GenericDataList& ds) {
			ds.pass(res);
		}

		/**
		 *  @brief  Set given value as a result of the library function
		 *  @tparam T - any type, for types not supported by default developers are encouraged to specialize this function template
		 */
		template<typename T>
		void set(const T& arg) {
			Setter<T>::set(*this, arg);
		}

		/************************************ utility functions ************************************/

		/**
		 * @brief 	Get ProgressMonitor shared with WL Kernel.
		 * @param 	step - step value for progress monitor
		 * @return	A new instance of ProgressMonitor class.
		 * @warning If you haven't specified "ProgressMonitor" option when loading the library function
		 * 			with PacletFunctionSet, then the behavior of \c getProgressMonitor is undefined.
		 */
		ProgressMonitor getProgressMonitor(double step = ProgressMonitor::getDefaultStep()) const;

		/**
		 *   @brief         Get type of MNumericArray at position \c index in \c Args
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MNumericArray type
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		numericarray_data_t getNumericArrayType(size_type index) const;

		/**
		 *   @brief         Perform operation on NumericArray created from MNumericArray argument at position \p index in \c Args
		 *   @tparam		Mode - passing mode of the NumericArray that will be processed
		 *   @tparam		Operator - any callable class
		 *   @tparam		OpArgs... - types of arguments of \c operator() in class \c Operator
		 *   @param[in]     index - position of MNumericArray in \c Args
		 *   @param[in]     opArgs - arguments of Operator::operator()
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @warning		Operator::operator() has to be a template that takes a const NumericArray<T>& as first argument
		 **/
		template<Passing Mode, class Operator, class... OpArgs>
		void operateOnNumericArray(size_type index, OpArgs&&... opArgs);

		/**
		 *   @brief         Perform operation on NumericArray created from MNumericArray argument at position \p index in \c Args
		 *   @tparam		Mode - passing mode of the NumericArray that will be processed
		 *   @tparam		Operator - any callable class
		 *   @param[in]     index - position of MNumericArray in \c Args
		 *   @param[in]     op - callable object (possibly lambda) that takes only one argument - a NumericArray
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		template<Passing Mode = Passing::Automatic, class Operator>
		void operateOnNumericArray(size_type index, Operator&& op);

		/**
		 *   @brief         Get type of MTensor at position \c index in \c Args
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MTensor type
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		unsigned char getTensorType(size_type index) const;

		/**
		 *   @brief         Perform operation on Tensor created from MTensor argument at position \p index in \c Args
		 *   @tparam		Mode - passing mode of the Tensor that will be processed
		 *   @tparam		Operator - any callable class
		 *   @tparam		OpArgs... - types of arguments of \c operator() in class \c Operator
		 *   @param[in]     index - position of MTensor in \c Args
		 *   @param[in]     opArgs - arguments of Operator::operator()
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @throws        ErrorName::MArgumentTensorError - if MTensor argument has incorrect type
		 *   @warning		Operator::operator() has to be a template that takes a const Tensor<T>& as first argument
		 **/
		template<Passing Mode, class Operator, class... Args>
		void operateOnTensor(size_type index, Args&&... opArgs);

		/**
		 *   @brief         Perform operation on Tensor created from MTensor argument at position \p index in \c Args
		 *   @tparam		Mode - passing mode of the Tensor that will be processed
		 *   @tparam		Operator - any callable class
		 *   @param[in]     index - position of MTensor in \c Args
		 *   @param[in]     op - callable object (possibly lambda) that takes only one argument - a Tensor
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @throws        ErrorName::MArgumentTensorError - if MTensor argument has incorrect type
		 **/
		template<Passing Mode = Passing::Automatic, class Operator>
		void operateOnTensor(size_type index, Operator&& op);

		/**
		 *   @brief         Get type of MImage at position \c index in \c Args
		 *   @param[in]     index - position of desired MArgument in \c Args
		 *   @returns       MImage type
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		imagedata_t getImageType(size_type index) const;

		/**
		 *   @brief         Perform operation on Image created from MImage argument at position \p index in \c Args
		 *   @tparam		Mode - passing mode of the Image that will be processed
		 *   @tparam		Operator - any callable class
		 *   @tparam		OpArgs... - types of arguments of \c operator() in class \c Operator
		 *   @param[in]     index - position of MImage in \c Args
		 *   @param[in]     opArgs - arguments of Operator::operator()
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @throws        ErrorName::MArgumentImageError - if MImage argument has incorrect type
		 *   @warning		Operator::operator() has to be a template that takes a const Image<T>& as first argument
		 **/
		template<Passing Mode, class Operator, class... Args>
		void operateOnImage(size_type index, Args&&... opArgs);

		/**
		 *   @brief         Perform operation on Image created from MImage argument at position \p index in \c Args
		 *   @tparam		Mode - passing mode of the Image that will be processed
		 *   @tparam		Operator - any callable class
		 *   @param[in]     index - position of MImage in \c Args
		 *   @param[in]     op - callable object (possibly lambda) that takes only one argument - an Image
		 *   @throws        ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 *   @throws        ErrorName::MArgumentImageError - if MImage argument has incorrect type
		 **/
		template<Passing Mode = Passing::Automatic, class Operator>
		void operateOnImage(size_type index, Operator&& op);

		/************************************ User-defined types registration ************************************/

		/**
		 * @brief   Helper structure that can be used to register user-defined argument types in LLU.
		 * @details If you want a type X to be supported as template argument for MArgumentManager::get<>, you must specialize CustomType<> for X
		 *          and this specialization must contain a type alias CorrespondingTypes which is defined to be a std::tuple of basic LibraryLink types,
		 *          from which an object of type X can be constructed. See online docs and MArgumentManager unit tests for examples.
		 * @tparam  T - any type you would like to treat as a user-defined LibraryLink argument type
		 */
		template<typename T>
		struct CustomType {
//			using CorrespondingTypes = std::tuple<...>;
		};

		/**
		 * @brief   Helper structure to fully customize the way MArgumentManager reads T as argument type.
		 * @details If T is a user-defined argument type, LLU will by default attempt to create an object of type T by reading values of corresponding types
		 *          and feeding it to a constructor of T. Specialize Getter<> to override this behavior.
		 * @note    Every user-defined argument type must specialize CustomType<>, specializing Getter<> is optional.
		 * @tparam  T - any type, for which you would like full control over how MArgumentManager reads arguments of that type
		 */
		template<typename T>
		struct Getter {
			/**
			 * A function that tells LLU how to interpret an object of a user-defined type as an argument of a library function
			 * This function is used internally by MArgumentManager::get.
			 * @param mngr - an instance of MArgumentManager
			 * @param firstIndex - index of the first library function parameter to be used
			 * @return an object of type \p T constructed from library function arguments stored in \p mngr
			 */
			static T get(const MArgumentManager& mngr, size_type firstIndex) {
				if constexpr (isCustomMArgumentType<T>) {
					return DefaultCustomGetter<T, typename CustomType<T>::CorrespondingTypes>::get(mngr, firstIndex);
				} else {
					static_assert(dependent_false_v<T>, "Unrecognized MArgument type passed as template parameter to MArgumentManager::get.");
					return {};
				}
			}
		};

		/**
		 * @brief   Helper structure to fully customize the way MArgumentManager sets an object of type T as result of a library function.
		 * @note    You can explicitly specialize MArgumentManager::set for your type T, but having Setter<> allows you to define partial specializations.
		 */
		template<typename T>
		struct Setter {
			/// A function that tells LLU how to send an object of a user-defined type as a result of a library function
			/// This function is used internally by MArgumentManager::set.
			static void set(MArgumentManager& /*mngr*/, const T& /*value*/) {
				static_assert(dependent_false_v<T>, "Unrecognized MArgument type passed as template parameter to MArgumentManager::set.");
			}
		};

	private:
		template<typename... ArgTypes>
		struct MArgPackGetter {
			template<size_type... Indices>
			static std::tuple<ArgTypes...>
			getImpl(const MArgumentManager& mngr, std::array<size_type, sizeof...(ArgTypes)> inds, std::index_sequence<Indices...> /*seq*/) {
				if (sizeof...(ArgTypes) > static_cast<size_type>(mngr.argc)) {
					ErrorManager::throwException(ErrorName::MArgumentIndexError);
				}
				return {mngr.get<ArgTypes>(inds[Indices])...};
			}
		};

		template<typename, typename>
		struct DefaultCustomGetter;
		template<typename T, typename... Args>
		struct DefaultCustomGetter<T, std::tuple<Args...>> {
			static T get(const MArgumentManager& mngr, size_type firstIndex) {
				return std::make_from_tuple<T>(mngr.getTuple<Args...>(firstIndex));
			}
		};

		template<typename T>
		struct CustomMArgumentTypeDetector {
			template<typename U>
			static std::true_type isSpecialized(typename CustomType<U>::CorrespondingTypes* /*unused*/) { return {}; }

			template<typename>
			static std::false_type isSpecialized(...) { return {}; } // NOLINT(cert-dcl50-cpp): this is a common idiom

			static constexpr bool value = decltype(isSpecialized<T>(nullptr))::value; // NOLINT(cppcoreguidelines-pro-type-vararg): this is a common idiom
		};

		template<typename T>
		static constexpr bool isCustomMArgumentType = CustomMArgumentTypeDetector<T>::value;

		template<typename T>
		static constexpr size_type getArgSlotCount() {
			if constexpr (isCustomMArgumentType<T>) {
				return std::tuple_size_v<typename CustomType<T>::CorrespondingTypes>;
			}
			return 1;
		}

		template<size_t N>
		static std::array<size_type, N> getOffsets(size_t I0, std::array<size_type, N> a) {
			if constexpr (N == 0) {
				return {};
			} else {
				std::array<size_type, N> offsets = {I0};
				for (size_t i = 1; i < N; ++i) {
					offsets[i] = offsets[i - 1] + a[i - 1];
				}
				return offsets;
			}
		}
		/********************************* End of user-defined types registration ************************************/

	private:

		// Efficient and memory-safe type for storing string arguments from LibraryLink
		using LLStringPtr = std::unique_ptr<char[], decltype(st_WolframLibraryData::UTF8String_disown)>;

		/**
		 *   @brief			Get MArgument at position \c index
		 *   @param[in]		index - position of desired MArgument in \c Args
		 *   @throws		ErrorName::MArgumentIndexError - if \c index is out-of-bounds
		 **/
		MArgument getArgs(size_type index) const;

		/**
		 * @brief Helper function to initialize string arguments vector
		 */
		void initStringArgs();

		/**
		 * @brief Take ownership of UTF8String argument passed via LibraryLink.
		 *
		 * This wraps the raw char* into unique_ptr and all further accesses to the argument happen via the unique_ptr.
		 * The string argument is automatically deallocated when MArgumentManager instance is destroyed.
		 *
		 * @param index - position of desired MArgument in \c Args
		 */
		void acquireUTF8String(size_type index) const;

		/**
		 * @brief   Convert passing mode to ownership info
		 * @param   m - passing mode
		 * @return  ownership corresponding to given passing mode ("Manual" -> Library, "Shared" -> Shared, else LibraryLink)
		 */
		static constexpr Ownership getOwner(Passing m) noexcept {
			if (m == Passing::Manual) {
				return Ownership::Library;
			}
			if (m == Passing::Shared) {
				return Ownership::Shared;
			}
			return Ownership::LibraryLink;
		}

		/// Here we store a string that was most recently returned to LibraryLink
		/// [LLDocs]: https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithMathematica.html#262826223 "LibraryLink docs"
		/// @see [LibraryLink docs][LLDocs]
		static std::string stringResultBuffer;

		/// Max \b mint value
		static constexpr mint MINT_MAX = (std::numeric_limits<mint>::max)();

		/// Min \b mint value
		static constexpr mint MINT_MIN = (std::numeric_limits<mint>::min)();

		/// Number of input arguments expected from LibraryLink
		mint argc;

		/// "Array" of input arguments from LibraryLink
		MArgument* args;

		/// Output argument for LibraryLink
		MArgument& res;

		/// Structure to manage string arguments after taking their ownership from LibraryLink
		/// [LLDocs]: https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithMathematica.html#262826223 "LibraryLink docs"
		/// @see [LibraryLink docs][LLDocs]
		mutable std::vector<LLStringPtr> stringArgs;
	};

/// @cond
	template<typename T>
	T MArgumentManager::getInteger(size_type index) const {
		return static_cast<T>(MArgument_getInteger(getArgs(index)));
	}

#define LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION(type, getFunction) \
	template<>                                                          \
	inline type MArgumentManager::get<type>(size_type index) const {    \
		return getFunction(index);                                      \
	}

	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION(bool, getBoolean)
	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION(double, getReal)
	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION(std::string, getString)
	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION(const char*, getCString)
	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION(std::complex<double>, getComplex)

#undef LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION

#define LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION_FOR_CONTAINER(Container)                                             \
	template<typename T> /* NOLINTNEXTLINE(bugprone-macro-parentheses): false positive here and below */                      \
	struct MArgumentManager::Getter<Container<T>> {                                                                           \
		static Container<T> get(const MArgumentManager& mngr, size_type index) { /* NOLINT(bugprone-macro-parentheses) */     \
			return mngr.get##Container<T, Passing::Automatic>(index);                                                         \
		}                                                                                                                     \
	};                                                                                                                        \
	template<typename T, Passing Mode>                                                                                        \
	struct MArgumentManager::Getter<MArgumentManager::Managed<Container<T>, Mode>> { /* NOLINT(bugprone-macro-parentheses) */ \
		static Container<T> get(const MArgumentManager& mngr, size_type index) {	 /* NOLINT(bugprone-macro-parentheses) */ \
			return mngr.get##Container<T, Mode>(index);                                                                       \
		}                                                                                                                     \
	};                                                                                                                        \
	template<>                                                                                                                \
	struct MArgumentManager::Getter<Generic##Container> {                                                                     \
		static Generic##Container get(const MArgumentManager& mngr, size_type index) {                                        \
			return mngr.getGeneric##Container<Passing::Automatic>(index);                                                     \
		}                                                                                                                     \
	};                                                                                                                        \
	template<Passing Mode>                                                                                                    \
	struct MArgumentManager::Getter<MArgumentManager::Managed<Generic##Container, Mode>> {                                    \
		static Generic##Container get(const MArgumentManager& mngr, size_type index) {                                        \
			return mngr.getGeneric##Container<Mode>(index);                                                                   \
		}                                                                                                                     \
	};

	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION_FOR_CONTAINER(NumericArray)
	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION_FOR_CONTAINER(Tensor)
	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION_FOR_CONTAINER(Image)
	LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION_FOR_CONTAINER(DataList)

#undef LLU_MARGUMENTMANAGER_GENERATE_GET_SPECIALIZATION_FOR_CONTAINER

	template<typename T>
	bool MArgumentManager::setMintAndCheck(T result) noexcept {
		if (result >= MINT_MAX) {
			setInteger(MINT_MAX);
			return true;
		}
		if (result <= MINT_MIN) {
			setInteger(MINT_MIN);
			return true;
		}
		setInteger(result);
		return false;
	}

	template<typename T, Passing Mode>
	NumericArray<T> MArgumentManager::getNumericArray(size_type index) const {
		return NumericArray<T> { getGenericNumericArray<Mode>(index) };
	}

	template<typename T>
	void MArgumentManager::setNumericArray(const NumericArray<T>& na) {
		na.pass(res);
	}

	template<Passing Mode, class Operator, class... Args>
	void MArgumentManager::operateOnNumericArray(size_type index, Args&&... opArgs) {
		Operator op;
		switch (getNumericArrayType(index)) {
			case MNumericArray_Type_Bit8: op(this->getNumericArray<int8_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_UBit8: op(this->getNumericArray<uint8_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_Bit16: op(this->getNumericArray<int16_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_UBit16: op(this->getNumericArray<uint16_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_Bit32: op(this->getNumericArray<int32_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_UBit32: op(this->getNumericArray<uint32_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_Bit64: op(this->getNumericArray<int64_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_UBit64: op(this->getNumericArray<uint64_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_Real32: op(this->getNumericArray<float, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_Real64: op(this->getNumericArray<double, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_Complex_Real32: op(this->getNumericArray<std::complex<float>, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MNumericArray_Type_Complex_Real64: op(this->getNumericArray<std::complex<double>, Mode>(index), std::forward<Args>(opArgs)...); break;
			default:
				ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentNumericArrayError,
														  "Incorrect type of NumericArray argument. Argument index: " + std::to_string(index));
		}
	}

	template<Passing Mode, class Operator>
	void MArgumentManager::operateOnNumericArray(size_type index, Operator&& op) {
		switch (getNumericArrayType(index)) {
			case MNumericArray_Type_Bit8: op(this->getNumericArray<int8_t, Mode>(index)); break;
			case MNumericArray_Type_UBit8: op(this->getNumericArray<uint8_t, Mode>(index)); break;
			case MNumericArray_Type_Bit16: op(this->getNumericArray<int16_t, Mode>(index)); break;
			case MNumericArray_Type_UBit16: op(this->getNumericArray<uint16_t, Mode>(index)); break;
			case MNumericArray_Type_Bit32: op(this->getNumericArray<int32_t, Mode>(index)); break;
			case MNumericArray_Type_UBit32: op(this->getNumericArray<uint32_t, Mode>(index)); break;
			case MNumericArray_Type_Bit64: op(this->getNumericArray<int64_t, Mode>(index)); break;
			case MNumericArray_Type_UBit64: op(this->getNumericArray<uint64_t, Mode>(index)); break;
			case MNumericArray_Type_Real32: op(this->getNumericArray<float, Mode>(index)); break;
			case MNumericArray_Type_Real64: op(this->getNumericArray<double, Mode>(index)); break;
			case MNumericArray_Type_Complex_Real32: op(this->getNumericArray<std::complex<float>, Mode>(index)); break;
			case MNumericArray_Type_Complex_Real64: op(this->getNumericArray<std::complex<double>, Mode>(index)); break;
			default:
				ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentNumericArrayError,
														  "Incorrect type of NumericArray argument. Argument index: " + std::to_string(index));
		}
	}

	template<typename T, Passing Mode>
	Tensor<T> MArgumentManager::getTensor(size_type index) const {
		return Tensor<T> { getGenericTensor<Mode>(index) };
	}

	template<typename T>
	void MArgumentManager::setTensor(const Tensor<T>& ten) {
		ten.pass(res);
	}

	template<Passing Mode, class Operator, class... Args>
	void MArgumentManager::operateOnTensor(size_type index, Args&&... opArgs) {
		Operator op;
		switch (getTensorType(index)) {
			case MType_Integer: op(this->getTensor<mint, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MType_Real: op(this->getTensor<double, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MType_Complex: op(this->getTensor<std::complex<double>, Mode>(index), std::forward<Args>(opArgs)...); break;
			default:
				ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentTensorError,
														  "Incorrect type of Tensor argument. Argument index: " + std::to_string(index));
		}
	}

	template<Passing Mode, class Operator>
	void MArgumentManager::operateOnTensor(size_type index, Operator&& op) {
		switch (getTensorType(index)) {
			case MType_Integer: op(this->getTensor<mint, Mode>(index)); break;
			case MType_Real: op(this->getTensor<double, Mode>(index)); break;
			case MType_Complex: op(this->getTensor<std::complex<double>, Mode>(index)); break;
			default:
				ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentTensorError,
														  "Incorrect type of Tensor argument. Argument index: " + std::to_string(index));
		}
	}

	template<typename T, Passing Mode>
	Image<T> MArgumentManager::getImage(size_type index) const {
		return Image<T> { getGenericImage<Mode>(index) };
	}

	template<typename T>
	void MArgumentManager::setImage(const Image<T>& im) {
		im.pass(res);
	}

	template<Passing Mode, class Operator, class... Args>
	void MArgumentManager::operateOnImage(size_type index, Args&&... opArgs) {
		Operator op;
		switch (getImageType(index)) {
			case MImage_Type_Bit: op(this->getImage<int8_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MImage_Type_Bit8: op(this->getImage<uint8_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MImage_Type_Bit16: op(this->getImage<uint16_t, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MImage_Type_Real32: op(this->getImage<float, Mode>(index), std::forward<Args>(opArgs)...); break;
			case MImage_Type_Real: op(this->getImage<double, Mode>(index), std::forward<Args>(opArgs)...); break;
			default:
				ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentImageError,
														  "Incorrect type of Image argument. Argument index: " + std::to_string(index));
		}
	}

	template<Passing Mode, class Operator>
	void MArgumentManager::operateOnImage(size_type index, Operator&& op) {
		switch (getImageType(index)) {
			case MImage_Type_Bit: op(std::move(this->getImage<int8_t, Mode>(index))); break;
			case MImage_Type_Bit8: op(this->getImage<uint8_t, Mode>(index)); break;
			case MImage_Type_Bit16: op(this->getImage<uint16_t, Mode>(index)); break;
			case MImage_Type_Real32: op(this->getImage<float, Mode>(index)); break;
			case MImage_Type_Real: op(this->getImage<double, Mode>(index)); break;
			default:
				ErrorManager::throwExceptionWithDebugInfo(ErrorName::MArgumentImageError,
														  "Incorrect type of Image argument. Argument index: " + std::to_string(index));
		}
	}

	template<typename T, Passing Mode>
	DataList<T> MArgumentManager::getDataList(size_type index) const {
		return DataList<T>(getGenericDataList<Mode>(index));
	}

	template<typename T>
	void MArgumentManager::setDataList(const DataList<T>& ds) {
		ds.pass(res);
	}

	template<Passing Mode>
	GenericNumericArray MArgumentManager::getGenericNumericArray(size_type index) const {
		return GenericNumericArray(getMNumericArray(index), getOwner(Mode));
	}

	template<Passing Mode>
	GenericTensor MArgumentManager::getGenericTensor(size_type index) const {
		return {getMTensor(index), getOwner(Mode)};
	}

	template<Passing Mode>
	GenericImage MArgumentManager::getGenericImage(size_type index) const {
		return {getMImage(index), getOwner(Mode)};
	}

	template<Passing Mode>
	GenericDataList MArgumentManager::getGenericDataList(size_type index) const {
		static_assert(Mode != Passing::Shared, "DataStore cannot be passed as \"Shared\".");
		return {getDataStore(index), getOwner(Mode)};
	}

	template<class ManagedExpr, class DynamicType>
	DynamicType& MArgumentManager::getManagedExpression(size_type index, ManagedExpressionStore<ManagedExpr>& store) const {
		auto ptr = getManagedExpressionPtr<ManagedExpr, DynamicType>(index, store);
		if (!ptr) {
			ErrorManager::throwException(ErrorName::MLEDynamicTypeError);
		}
		return *ptr;
	}

	template<class ManagedExpr, class DynamicType>
	std::shared_ptr<DynamicType> MArgumentManager::getManagedExpressionPtr(size_type index, ManagedExpressionStore<ManagedExpr>& store) const {
		auto exprID = getInteger<mint>(index);
		auto baseClassPtr = store.getInstancePointer(exprID);
		return std::dynamic_pointer_cast<DynamicType>(baseClassPtr);
	}
/// @endcond
} /* namespace LLU */

#endif // LLU_MARGUMENTMANAGER_H
