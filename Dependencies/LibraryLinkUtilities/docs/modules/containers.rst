=================================================
Containers
=================================================


Raw LibraryLink containers like MTensor or MNumericArray store their element type as a regular field in the structure.
This means that the type cannot be used at compile-time, which makes writing generic code that does something with
the underlying data very difficult (lots of switches on the element type and code repetition).

On the other hand, having the element type as template parameter, like STL containers, is often inconvenient and requires
some template magic for simple things like passing forward the container or reading metadata when the data type is not
known a priori.

To get the best of both worlds and to make the library suitable for different needs, LLU provides two categories of container wrappers -
generic, datatype-agnostic wrappers and full-fledged wrappers templated with the datatype. This is illustrated in the table below:

+----------------------------------------------+----------------------------------------------+----------------------------------------+
| LibraryLink element                          |    Generic wrapper                           |   Typed wrapper                        |
+==============================================+==============================================+========================================+
|    :ref:`MTensor <mtensor-label>`            | :ref:`GenericTensor <generictensor-label>`   | :ref:`Tensor\<T> <tensor-label>`       |
+----------------------------------------------+----------------------------------------------+----------------------------------------+
| :ref:`MNumericArray <mnumericarray-label>`   | :ref:`GenericNumericArray <genericna-label>` | :ref:`NumericArray\<T> <numarr-label>` |
+----------------------------------------------+----------------------------------------------+----------------------------------------+
|    :ref:`MImage <mimage-label>`              | :ref:`GenericImage <genericimg-label>`       | :ref:`Image\<T> <image-label>`         |
+----------------------------------------------+----------------------------------------------+----------------------------------------+
|    :ref:`DataStore <datastore-label>`        | :ref:`GenericDataList <genericdl-label>`     | :ref:`DataList\<T> <datalist-label>`   |
+----------------------------------------------+----------------------------------------------+----------------------------------------+
|    :ref:`MSparseArray <msparsearray-label>`  |                      ⊝                       |          ⊝                             |
+----------------------------------------------+----------------------------------------------+----------------------------------------+

Memory management
============================

When passing a container from Wolfram Language to a C++ library, one of 4 passing modes must be chosen:

* Automatic
* Constant
* Manual
* Shared

With the exception of DataStore, which cannot be Constant or Shared.

More about memory management can be found in the
`LibraryLink documentation <https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage.html#97446640>`_.

In plain LibraryLink, the choice you make is reflected only in the Wolfram Language code where :wlref:`LibraryFunctionLoad` specifies
the list of parameters for the library function. There is no way to query the WolframLibraryData or MArgument about
the passing modes of function arguments from within C++ code. Therefore, the programmer must remember the passing mode
for each argument and then ensure the correct action is taken (releasing/not releasing memory depending
on the combination of passing mode and whether the container has been returned from the library function to the Wolfram Language).

LLU defines a notion of *container ownership*:

.. doxygenenum:: LLU::Ownership

LLU ensures that at any point of time every container has a well-defined owner. The ownership is mostly static and may change only on a few occasions e.g.
when passing a container to DataList or setting it as a result of a library function.

When a container is received from the Wolfram Language as an argument to a library function, the developer must inform the :cpp:class:`MArgumentManager<LLU::MArgumentManager>`
about the passing mode used for that container. There is a separate enumeration for this purpose:

.. doxygenenum:: LLU::Passing

The ``Passing`` value is used by the :cpp:class:`MArgumentManager<LLU::MArgumentManager>` to determine the initial owner of the container.

Here are some examples:

.. code-block:: cpp
   :dedent: 1

    LLU::Tensor<mint> t { 1, 2, 3, 4, 5 };    // this Tensor is created (and therefore owned) by the library (LLU)

    LLU::MArgumentManager manager {...};
    auto tensor = manager.getTensor<double>(0);  // tensors acquired via MArgumentManager are by default owned by the LibraryLink

    auto image = manager.getGenericImage<LLU::Passing::Shared>(0);    // the image is shared between LLU and the Kernel, so LLU knows not to deallocate
                                                                      // the underlying MImage when image goes out of scope

    auto newImage = image.clone();    // the newImage has the same contents as image but it is not shared, it is owned by LLU


More examples can be found in the unit tests.

Raw Containers
============================

These are just raw LibraryLink containers.

.. _datastore-label:

DataStore
----------------------------

``DataStore`` is C structure (technically, a pointer to structure) defined in the WolframLibrary. It is a unidirectional linked list of immutable nodes.
Each node consists of a *name* (``char*``) and *value* (``MArgument``). DataStore itself can be stored in the MArgument union, which means that DataStores
can be nested. DataStores can be passed to and from library functions. Existing nodes cannot be removed but adding new nodes is supported.

The complete DataStore API can be found inside Wolfram Language (12.0+) installations at  :file:`SystemFiles/IncludeFiles/C/WolframIOLibraryFunctions.h`.

On the Wolfram Language side a ``DataStore`` is represented as an expression with head ``Developer`DataStore`` that takes a list of expressions, where each
expressions is either:

 - a value of type supported by LibraryLink (String, Integer, NumericArray, etc.)
 - a :wlref:`Rule` with the LHS being a String and RHS of the form described in the previous point

For example:

.. code-block:: wolfram-language

   Developer`DataStore["node_name1" -> 42, NumericArray[{1,2,3,4}, "Integer8"], "node_name3" -> "node_value3"]


.. _mimage-label:

MImage
----------------------------

A structure corresponding to Wolfram Language expressions :wlref:`Image` and :wlref:`Image3D`.
Documented in `LibraryLink » MImage <https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage.html#441025439>`_.

.. _mnumericarray-label:

MNumericArray
----------------------------

A structure corresponding to Wolfram Language expressions :wlref:`NumericArray`.
Documented in `LibraryLink » MNumericArray <https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage.html#106266186>`_.

.. _mtensor-label:

MTensor
----------------------------

A structure corresponding to packed arrays in the Wolfram Language.
Documented in `LibraryLink » MTensor <https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage.html#280210622>`_.

.. _msparsearray-label:

MSparseArray
----------------------------

A structure corresponding to Wolfram Language expressions :wlref:`SparseArray`.
Documented in `LibraryLink » MSparseArray <https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage.html#1324196729>`_.

Generic Wrappers
======================================

These are datatype-unaware wrappers that offer automatic memory management and basic interface-like access to metadata (dimensions, rank, etc).
They do not provide direct access to the underlying data except via a :cpp:expr:`void*` (or via a generic node type :cpp:any:`LLU::NodeType::Any` in case of a
GenericDataList).

.. tip::

   All generic and strongly-typed wrappers are movable but non-copyable, instead they provide a :cpp:expr:`clone()` method for performing deep copies.
   This is in accordance with rule `C.67 <http://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#c67-a-polymorphic-class-should-suppress-copying>`_
   from the C++ Core Guidelines but most of all preventing accidental deep copies of containers is beneficial in terms of performance.

.. _genericdl-label:

:cpp:type:`LLU::GenericDataList`
------------------------------------

GenericDataList is a light-weight wrapper over :ref:`datastore-label`. It offers access to the underlying nodes via iterators and a
:cpp:func:`push_back <LLU::MContainer\< MArgumentType::DataStore >::push_back>` method for appending new nodes. You can also get the length of the list.


Here is an example of GenericDataList in action:

.. code-block:: cpp
   :linenos:

   /* Reverse each string in a list of strings using GenericDataList */
   LIBRARY_LINK_FUNCTION(ReverseStrings) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};

      // read the input GenericDataList
      auto dsIn = mngr.get<LLU::GenericDataList>(0);

      // create new GenericDataList to store reversed strings
      LLU::GenericDataList dsOut;

      for (auto node : dsIn) {
         // GenericDataList may store nodes of arbitrary type, so we need to explicitly ask to get the string value from the node
         std::string_view s = node.as<LLU::NodeType::UTF8String>();

         std::string reversed {s.rbegin(), s.rend()};	// create reversed copy

         // we push back the reversed string via a string_view, this is safe because GenericDataList will immediately copy the string
         dsOut.push_back(std::string_view(reversed));
      }

      // set the GenericDataList as the result of the library function
      mngr.set(dsOut);
      return LLU::ErrorCode::NoError;
   }

Technically, GenericDataList is an alias:

.. doxygentypedef:: LLU::GenericDataList

.. doxygenclass:: LLU::MContainer< MArgumentType::DataStore >
   :members:

.. _genericimg-label:

:cpp:type:`LLU::GenericImage`
------------------------------------

GenericImage is a light-weight wrapper over :ref:`mimage-label`. It offers the same API as LibraryLink has for MImage, except for access to the image data,
because GenericImage is not aware of the image data type. Typically one would use GenericImage to take an Image of unknown type from LibraryLink, investigate
image properties and data type and then upgrade the GenericImage to the strongly-typed one in order to perform operations on the image data.

Here is an example of GenericImage in action:

.. code-block:: cpp
   :linenos:

   /* Get the number of columns in the input Image */
   LIBRARY_LINK_FUNCTION(GetColumnCount) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};
      const auto image = mngr.getGenericImage<LLU::Passing::Constant>(0);
      mngr.setInteger(image.columns());
      return LLU::ErrorCode::NoError;
   }


.. doxygentypedef:: LLU::GenericImage

.. doxygenclass:: LLU::MContainer< MArgumentType::Image >
   :members:

.. _genericna-label:

:cpp:type:`LLU::GenericNumericArray`
------------------------------------

GenericNumericArray is a light-weight wrapper over :ref:`mnumericarray-label`. It offers the same API as LibraryLink has for MNumericArray, except for access
to the underlying array data, because GenericNumericArray is not aware of the array data type. Typically on would use GenericNumericArray to take a NumericArray
of unknown type from LibraryLink, investigate its properties and data type and then upgrade the GenericNumericArray to the strongly-typed one in order to
perform operations on the underlying data.

Here is an example of GenericNumericArray in action:

.. code-block:: cpp
   :linenos:

   /* Return the largest dimension of the input NumericArray */
   LIBRARY_LINK_FUNCTION(GetLargestDimension) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};
      const auto numericArray = mngr.getGenericNumericArray<LLU::Passing::Constant>(0);

      // The list of dimensions of the NumericArray will never be empty because scalar NumericArrays are forbidden
      auto maxDim = *std::max_element(numericArray.getDimensions(), std::next(numericArray.getDimensions(), numericArray.getRank()));
      mngr.setInteger(maxDim);
      return LLU::ErrorCode::NoError;
   }

.. doxygentypedef:: LLU::GenericNumericArray

.. doxygenclass:: LLU::MContainer< MArgumentType::NumericArray >
   :members:

.. _generictensor-label:

:cpp:type:`LLU::GenericTensor`
------------------------------------

GenericTensor is a light-weight wrapper over :ref:`mtensor-label`. It offers the same API that LibraryLink has for MTensor, except for access
to the underlying array data because GenericTensor is not aware of the array data type. Typically on would use GenericTensor to take a Tensor
of an unknown type from LibraryLink, investigate its properties and data type, then upgrade the GenericTensor to the strongly-typed one in order to
perform operations on the underlying data.

.. doxygentypedef:: LLU::GenericTensor

.. doxygenclass:: LLU::MContainer< MArgumentType::Tensor >
   :members:

Typed Wrappers
============================

Typed wrappers are full-fledged wrappers with automatic memory management (see section below), type-safe data access, iterators, etc.
All typed wrappers are movable but non-copyable, instead they provide a :cpp:expr:`clone()` method for performing deep copies.

.. _datalist-label:

:cpp:class:`LLU::DataList\<T> <template\<typename T> LLU::DataList>`
-------------------------------------------------------------------------------

DataList is a strongly-typed wrapper derived from GenericDataList in which all nodes must be of the same type and be known at compile time. Template parameter
``T`` denotes the value type of nodes. Supported node value types are shown below with corresponding types of raw DataStore nodes and with underlying C++ types:

+-------------------------+--------------------------+------------------------+
| Node Type Name          | Underlying Type          | Raw DataStoreNode Type |
+=========================+==========================+========================+
| NodeType::Boolean       | bool                     | mbool                  |
+-------------------------+--------------------------+------------------------+
| NodeType::Integer       | mint                     | mint                   |
+-------------------------+--------------------------+------------------------+
| NodeType::Real          | double                   | mreal                  |
+-------------------------+--------------------------+------------------------+
| NodeType::Complex       | std::complex<double>     | mcomplex               |
+-------------------------+--------------------------+------------------------+
| NodeType::Tensor        | LLU::GenericTensor       | MTensor                |
+-------------------------+--------------------------+------------------------+
| NodeType::SparseArray   | MSparseArray             | MSparseArray           |
+-------------------------+--------------------------+------------------------+
| NodeType::NumericArray  | LLU::GenericNumericArray | MNumericArray          |
+-------------------------+--------------------------+------------------------+
| NodeType::Image         | LLU::GenericImage        | MImage                 |
+-------------------------+--------------------------+------------------------+
| NodeType::UTF8String    | std::string_view         | char*                  |
+-------------------------+--------------------------+------------------------+
| NodeType::DataStore     | LLU::GenericDataList     | DataStore              |
+-------------------------+--------------------------+------------------------+

``LLU::NodeType`` is a namespace alias for ``LLU::Argument::Typed`` which is defined as follows:

.. doxygennamespace:: LLU::Argument::Typed

Notice that :cpp:expr:`LLU::NodeType::Any` (or equivalently :cpp:expr:`LLU::Argument::Typed::Any`) is a special type which is a union of all other types
from its namespace. In a way it corresponds to :cpp:expr:`MArgument` type in LibraryLink. A DataList with node type :cpp:expr:`LLU::NodeType::Any` can store
nodes of any types so it is quite similar to :cpp:expr:`LLU::GenericDataList` but it has the interface of DataList, meaning that it offers more advanced
iterators and more constructors.

Here is an example of the DataList class in action:

.. code-block:: cpp
   :linenos:

   /* Take a list of named nodes with complex numbers and create two new lists: a list of node names and a list of node values */
   LIBRARY_LINK_FUNCTION(SeparateKeysAndValues) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};

      auto dsIn = mngr.getDataList<LLU::NodeType::Complex>(0);
      LLU::DataList<LLU::NodeType::UTF8String> keys;
      LLU::DataList<LLU::NodeType::Complex> values;

      // For each node in the input DataList push its name to "keys" and its value to "values"
      for (auto [name, value] : dsIn) {
        keys.push_back(name);
        values.push_back(value);
      }

      LLU::DataList<LLU::GenericDataList> dsOut;
      dsOut.push_back("Keys", std::move(keys));
      dsOut.push_back("Values", std::move(values));

      mngr.set(dsOut);
      return LLU::ErrorCode::NoError;
   }

On the Wolfram Language side, we can load and use this function as follows:

.. code-block:: wolfram-language

   `LLU`PacletFunctionSet[SeparateKeysAndValues, "SeparateKeysAndValues", {"DataStore"}, "DataStore"];

   SeparateKeysAndValues[Developer`DataStore["a" -> 1 + 2.5 * I, "b" -> -3. - 6.I, 2I]]

   (* Out[] = Developer`DataStore["Keys" -> Developer`DataStore["a", "b", ""], "Values" -> Developer`DataStore[1. + 2.5 * I, -3. - 6.I, 2.I]] *)

.. doxygenclass:: LLU::DataList
   :members:

.. _image-label:

:cpp:class:`LLU::Image\<T> <template\<typename T> LLU::Image>`
-------------------------------------------------------------------------------

Image is a strongly-typed wrapper derived from GenericImage, where the underlying data type is known at compile time and encoded in the template parameter.
The table below shows the correspondence between Image data types in LLU, plain LibraryLink and in the Wolfram Language:

+-----------------+--------------------+-----------------------+
| LLU (C++) type  | LibraryLink type   | Wolfram Language type |
+=================+====================+=======================+
| std::int8_t     | MImage_Type_Bit    | "Bit"                 |
+-----------------+--------------------+-----------------------+
| std::uint8_t    | MImage_Type_Bit8   | "Byte"                |
+-----------------+--------------------+-----------------------+
| std::int16_t    | MImage_Type_Bit16  | "Bit16"               |
+-----------------+--------------------+-----------------------+
| float           | MImage_Type_Real32 | "Real32"              |
+-----------------+--------------------+-----------------------+
| double          | MImage_Type_Real   | "Real64"              |
+-----------------+--------------------+-----------------------+

Here is an example of the Image class in action:

.. code-block:: cpp
   :linenos:

   /* Take a constant "Byte" image and return a copy with negated pixel values */
   LIBRARY_LINK_FUNCTION(NegateImage) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};

      const auto image = mngr.getImage<uint8_t, LLU::Passing::Constant>(0);

      LLU::Image<uint8_t> outImage {image.clone()};
      constexpr uint8_t negator = (std::numeric_limits<uint8_t>::max)();
      std::transform(std::cbegin(in), std::cend(in), std::begin(outImage), [](T inElem) { return negator - inElem; });

      mngr.setImage(outImage);
      return LLU::ErrorCode::NoError;
   }

On the Wolfram Language side, we can load and use this function as follows:

.. code-block:: wolfram-language

   `LLU`PacletFunctionSet[NegateImage, "NegateImage", {{Image, "Constant"}}, Image];

   NegateImage[Image[RandomImage[ColorSpace -> "RGB"], "Byte"]]

   (* Out[] = [--Image--] *)

This is only an example, Wolfram Language already has a built-in function for negating images: :wlref:`ImageNegate`.

In the example above we simply assumed that the Image we use will be of type "Byte", so we could simply write :cpp:expr:`LLU::Image<uint8_t>` in the C++ code.
In the next example let's consider a function that takes two images from LibraryLink of arbitrary types and converts the second one to the data type of the
first one. In this case we cannot simply read arguments from MArgumentManager because we don't know what template arguments should be passed to LLU::Image.
Instead, we call a function :cpp:func:`LLU::MArgumentManager::operateOnImage` which lets us evaluate a function template on an input image without knowing its data type.

.. code-block:: cpp
   :linenos:

   LIBRARY_LINK_FUNCTION(UnifyImageTypes) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};

      // Take an image passed to the library function as the first argument, deduce its data type, create a corresponding LLU::Image wrapper and evaluate
      // given generic lambda function on this image
      mngr.operateOnImage(0, [&mngr](auto&& firstImage) {

         // T is the data type of the first image
         using T = typename std::remove_reference_t<decltype(firstImage)>::value_type;

         // Similarly, read the second image and create a properly typed LLU::Image wrapper
         mngr.operateOnImage(1, [&mngr](auto&& secondImage) {

            // Convert the second image to the data type of the first one and return as the library function result
            LLU::Image<T> out {secondImage.template convert<T>()};
            mngr.setImage(out);
         });
      });
      return LLU::ErrorCode::NoError;
   }


.. doxygenclass:: LLU::Image
   :members:

.. _numarr-label:

:cpp:class:`LLU::NumericArray\<T> <template\<typename T> LLU::NumericArray>`
-------------------------------------------------------------------------------

NumericArray<T> is an extension of GenericNumericArray which is aware that it holds data of type T and therefore can provide an API
to iterate over the data and modify it.
The table below shows the correspondence between NumericArray C++ types and Wolfram Language types:

+------------------------+-----------------------+
| C++ type               | Wolfram Language type |
+========================+=======================+
| std::int8_t            | "Integer8"            |
+------------------------+-----------------------+
| std::uint8_t           | "UnsignedInteger8"    |
+------------------------+-----------------------+
| std::int16_t           | "Integer16"           |
+------------------------+-----------------------+
| std::uint16_t          | "UnsignedInteger16"   |
+------------------------+-----------------------+
| std::int32_t           | "Integer32"           |
+------------------------+-----------------------+
| std::uint32_t          | "UnsignedInteger32"   |
+------------------------+-----------------------+
| std::int64_t           | "Integer64"           |
+------------------------+-----------------------+
| std::uint64_t          | "UnsignedInteger64"   |
+------------------------+-----------------------+
| float                  | "Real32"              |
+------------------------+-----------------------+
| double                 | "Real64"              |
+------------------------+-----------------------+
| std::complex<float>    | "ComplexReal32"       |
+------------------------+-----------------------+
| std::complex<double>   | "ComplexReal64"       |
+------------------------+-----------------------+

Here is an example of the NumericArray class in action:

.. code-block:: cpp
   :linenos:

   /* Take a NumericArray of type "Integer32" and make a copy with reversed order of elements */
   LIBRARY_LINK_FUNCTION(ReverseNumericArray) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};
      auto inputNA = mngr.getNumericArray<std::int32_t, LLU::Passing::Constant>(0);
      LLU::NumericArray<std::int32_t> outNA { std::crbegin(inputNA), std::crend(inputNA), inputNA.dimensions() };
      mngr.set(outNA);
      return LLU::ErrorCode::NoError;
   }

On the Wolfram Language side, we can load and use this function as follows:

.. code-block:: wolfram-language

   `LLU`PacletFunctionSet[ReverseNumericArray, "ReverseNumericArray", {{NumericArray, "Constant"}}, NumericArray];

   ReverseNumericArray[NumericArray[{{2, 3, 4}, {5, 6, 7}}, "Integer32"]]

   (* Out[] = NumericArray[{{7, 6, 5}, {4, 3, 2}}, "Integer32"] *)

.. doxygenclass:: LLU::NumericArray
   :members:

.. _tensor-label:

:cpp:class:`LLU::Tensor\<T> <template\<typename T> LLU::Tensor>`
-------------------------------------------------------------------------------

In the same way as MTensor is closely related to MNumericArray, :cpp:expr:`LLU::Tensor` has almost exactly the same interface as :cpp:expr:`LLU::NumericArray`.
Tensor supports only 3 types of data, meaning that :cpp:class:`template\<typename T> LLU::Tensor` class template can be instantiated with only 3 types ``T``:

  - ``mint``
  - ``double``
  - ``std::complex<double>``


Here is an example of the Tensor class in action:

.. code-block:: cpp
   :linenos:

   /* Take a Tensor of real numbers and return the mean value */
   LIBRARY_LINK_FUNCTION(GetMeanValue) {
      LLU::MArgumentManager mngr {libData, Argc, Args, Res};

      auto t = mngr.getTensor<double>(0);

      auto total = std::accumulate(t.begin(), t.end(), 0.0);

      auto result = total / t.size();
      mngr.set(result);
      return LLU::ErrorCode::NoError;
   }

On the Wolfram Language side, we can load and use this function as follows:

.. code-block:: wolfram-language

   `LLU`PacletFunctionSet[MeanValue, "MeanValue", {{Real, _}}, Real];

   MeanValue[N @ {{Pi, Pi, Pi}, {E, E, E}}]

   (* Out[] = 2.9299372 *)

.. doxygenclass:: LLU::Tensor
   :members:


Iterators
========================

All container classes in LLU are equipped with iterators. For Image, Tensor and NumericArray we get random-access iterators similar to those of, for instance,
:cpp:expr:`std::vector`, because these containers also allocate space for their data as a contiguous piece of memory. Reverse and constant iterators are
available as well.

.. warning::
   Bear in mind that iterators for Image, Tensor and NumericArray are not aware of the container dimensions in the sense that the iteration happens in the
   order in which data is laid out in memory. For 2D arrays this is often row-major order but it gets more complicated for multidimensional arrays
   and for Images.

DataStore wrappers have different iterators, because DataStore has a list-like structure with nodes of type :cpp:expr:`DataStoreNode`. The list is
unidirectional, so reverse iterator is not available. The default iterator over GenericDataList, obtained with
:cpp:func:`begin <LLU::MContainer\< MArgumentType::DataStore >::begin>` and :cpp:func:`end <LLU::MContainer\< MArgumentType::DataStore >::end>`, is a proxy
iterator of type :cpp:class:`DataStoreIterator`.

.. doxygenclass:: LLU::DataStoreIterator
   :members:

The object obtained by dereferencing a :cpp:class:`DataStoreIterator` is of type :cpp:class:`GenericDataNode`.

.. doxygenstruct:: LLU::GenericDataNode
   :members:

:cpp:class:`LLU::DataList\<T> <template\<typename T> LLU::DataList>` offers more types of iterators but again all of them are proxy iterators.
The default one is :cpp:class:`NodeIterator<T>`

.. doxygenstruct:: LLU::NodeIterator
   :members:

The object obtained by dereferencing a :cpp:class:`NodeIterator<T>` is of type :cpp:class:`DataNode<T>`.

.. doxygenclass:: LLU::DataNode
   :members:

Every data node has a (possibly empty) name and a value. Sometimes you might only be interested in node values, or only in names; DataList provides
specialized iterators for this. You may obtain them with :cpp:func:`valueBegin() <LLU::DataList::valueBegin>` and
:cpp:func:`nameBegin() <LLU::DataList::nameBegin>`, respectively.

To get those specialized iterators in a range-based for loop, where you cannot directly choose which variant of :cpp:expr:`begin()` method to use, you can
utilize one of the *iterator adaptors* that LLU defines. For instance,

.. code-block:: cpp
   :emphasize-lines: 6, 12

   // Get a DataList of complex numbers as argument to the library function
   auto dataList = manager.getDataList<LLU::NodeType::Complex>(0);

   // Create a new DataList to store node names of the original DataList as node values in the new list
   DataList<LLU::NodeType::UTF8String> keys;
   for (auto name : LLU::NameAdaptor {dataList}) {
      keys.push_back(name);
   }

   // Create a new DataList to store node values of the original DataList, without node names
   DataList<LLU::NodeType::Complex> values;
   for (auto value : LLU::ValueAdaptor {dataList}) {
      values.push_back(value);
   }

It is possible to write the same code using the default iterator (:cpp:class:`NodeIterator<T>`) and structured bindings:

.. code-block:: cpp
   :emphasize-lines: 8

   // Get a DataList of complex numbers as argument to the library function
   auto dataList = manager.getDataList<LLU::NodeType::Complex>(0);

   DataList<LLU::NodeType::UTF8String> keys;
   DataList<LLU::NodeType::Complex> values;

   // Iterate over the dataList once, accessing both node name and value
   for (auto [name, value] : dataList) {
      keys.push_back(name);
      values.push_back(value);
   }