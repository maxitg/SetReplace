.. include:: ../globals.rst

===========================================
Library functions
===========================================

By *library function* (also *LibraryLink function*) we understand a C++ function with one of the following signatures

.. code-block:: cpp

  EXTERN_C DLLEXPORT int f (WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res);

or

.. code-block:: cpp

  EXTERN_C DLLEXPORT int f (WolframLibraryData libData, WSLINK wslp);

Such functions are building blocks of every LibraryLink paclet. They are usually called directly from the Wolfram Language after being loaded from the dynamic
library first. It is common for paclets to also define functions entirely in the Wolfram Language or provide thin Wolfram Language wrappers around loaded
library functions for instance in order to validate input data and then pass it down to the C++ code.

Function arguments
======================

Passing data between Wolfram Language and external C or C++ libraries is a core feature of LibraryLink. This is far from a straightforward task, because in the
Wolfram Language everything is an expression and variable's type can change at run time, whereas C and C++ variables are statically typed. Apart from that,
every C/C++ library may define custom data types it uses.

LibraryLink does the heavy lifting by providing translation between popular Wolfram Language expression types and corresponding C types. For instance, when you
pass a ``String`` expression to the library function, you will receive a null-terminated ``char*`` in the C code, or passing a ``NumericArray`` will yield
an object of type ``MNumericArray``.

In practice, what you will receive in a library function as input arguments from the Wolfram Language is an array of ``MArgument``, which is a union type::

	typedef union {
		mbool *boolean;
		mint *integer;
		mreal *real;
		mcomplex *cmplex;
		MTensor *tensor;
		MSparseArray *sparse;
		MNumericArray *numeric;
		MImage *image;
		char **utf8string;
	} MArgument;


Similarly, there is one ``MArgument`` to store the result of your library function that you want to return to the Wolfram Language. You must also remember that
some types of arguments need special treatment, for example you must call ``UTF8String_disown`` on string arguments to avoid memory leaks.

Developers who are not familiar with this part of LibraryLink are encouraged to consult the
`official guide <https://reference.wolfram.com/language/LibraryLink/tutorial/LibraryStructure.html#606935091>`_ before reading on.

:term:`LLU` hides all those implementation details in the :cpp:class:`MArgumentManager<LLU::MArgumentManager>` class. You still need to know what the actual
argument types are but you can now extract arguments using member functions like :cpp:func:`getInteger<LLU::MArgumentManager::getInteger>`,
:cpp:func:`getString<LLU::MArgumentManager::getString>` etc. and set the resulting value with :cpp:func:`set<LLU::MArgumentManager::set>` without
worrying about memory management.

Example
================

Write a library function that adds two integers. First thing you need to do is to create an instance of :cpp:class:`MArgumentManager<LLU::MArgumentManager>`
initialized with all arguments to the library function:

.. code-block:: cpp

   EXTERN_C DLLEXPORT int AddTwoIntegers(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
       LLU::MArgumentManager mngr {libData, Argc, Args, Res};
       auto n1 = mngr.get<mint>(0);  // get first (index = 0) argument, which is of type mint
       auto n2 = mngr.get<mint>(1);  // get second argument which is also an integer

       mngr.set(n1 + n2);  // set the sum of arguments to be the result
       return LLU::ErrorCode::NoError;
   }

Such function, when compiled into a shared library, say :file:`myLib.so`, could be loaded into WolframLanguage and used like this:

.. code-block:: wolfram-language

   AddInts = LibraryFunctionLoad["myLib", "AddTwoIntegers", {Integer, Integer}, Integer];

   AddInts[17, 25]
   (* = 42 *)

Loading library functions
=============================

In the example above we saw how library functions can be loaded from shared objects via :wlref:`LibraryFunctionLoad`:

.. code-block:: wolfram-language

   FunctionNameInWL = LibraryFunctionLoad["path/to/sharedLibrary", "FunctionNameInCppCode", {ArgumentType1, ArgumentType2, ...}, ResultType];

The syntax is described in details in
`LibraryLink » Functions, Arguments, and Results <https://reference.wolfram.com/language/LibraryLink/tutorial/LibraryStructure.html#606935091>`_.

In case of WSTP library functions, the call gets simplified to:

.. code-block:: wolfram-language

   FunctionNameInWL = LibraryFunctionLoad["path/to/sharedLibrary", "FunctionNameInCppCode", LinkObject, LinkObject];

It is common but not in any way required to have ``FunctionNameInWL`` be equal to ``FunctionNameInCppCode`` with a ``$`` prepended, e.g.

.. code-block:: wolfram-language

   $FunctionName = LibraryFunctionLoad["path/to/sharedLibrary", "FunctionName", LinkObject, LinkObject]

LLU expands the library loading mechanism in LibraryLink by providing convenient wrappers with extra options:

:wldef:`SafeLibraryLoad[lib_]`
	Quietly attempts to load the dynamic library ``lib``, and throws if it cannot be loaded.

:wldef:`PacletFunctionSet[resultSymbol_, lib_, f_, fParams_, fResultType_, opts___]`
	Attempts to load an exported function ``f`` from a dynamic library ``lib`` and assign the result to ``resultSymbol``.
	By default, the dynamic library name is taken from the library given to ``InitializePacletLibrary`` (*Paclet Library*).
	A caveat is that if *Paclet Library* has been lazily initialized and ``PacletFunctionSet`` is called with a path to it, then
	auto-loading of *Paclet Library* will not be triggered.
	By default, the name of the library function is assumed to be the same as the symbol name (sans any leading or trailing $'s).

	Arguments:
		- ``resultSymbol`` - a WL symbol to represent the loaded function
		- ``lib`` - name of the dynamic library *[optional]*
		- ``f`` - name of the function to load from the dynamic library *[optional]*
		- ``fParams`` - parameter types of the library function to be loaded
		- ``fResultType`` - result type

:wldef:`LazyPacletFunctionSet[resultSymbol_, lib_, f_, fParams_, fResultType_, opts___]`
	Lazy version of ``PacletFunctionSet`` which loads the function upon the first evaluation of ``resultSymbol``.

:wldef:`WSTPFunctionSet[resultSymbol_, lib_, f_, opts___]`
	A convenient wrapper around ``PacletFunctionSet`` for easier loading of WSTP functions. Argument and result type are fixed as ``LinkObject``.

:wldef:`LazyWSTPFunctionSet[resultSymbol_, lib_, f_, opts___]`
	Lazy version of ``WSTPFunctionSet`` which loads the function upon the first evaluation of ``resultSymbol``.

:wldef:`MemberFunctionSet[exprHead_][memberSymbol_?Developer\`SymbolQ, lib_, f_, fParams_, retType_, opts___]`
	Loads a library function into ``memberSymbol`` that can be invoked on instances of ``exprHead`` like so: :wl:`instance @ memberSymbol[...]`

:wldef:`LazyMemberFunctionSet[exprHead_][memberSymbol_?Developer\`SymbolQ, lib_, f_, fParams_, retType_, opts___]`
	Lazy version of ``MemberFunctionSet`` which loads the function upon the first evaluation of ``memberSymbol``.

:wldef:`WSTPMemberFunctionSet[exprHead_][memberSymbol_, lib_, f_, opts___]`
	A convenient wrapper around ``MemberFunctionSet`` for easier loading of WSTP member functions.

:wldef:`LazyWSTPMemberFunctionSet[exprHead_][memberSymbol_, lib_, f_, opts___]`
	Lazy version of ``WSTPMemberFunctionSet`` which loads the function upon the first evaluation of ``memberSymbol``.

There is also one lower level function which does not take a symbol as first argument but instead returns the loaded library function as the result

:wldef:`PacletFunctionLoad[lib_, f_, fParams_, retType_, opts___]`
	Attempts to load an exported function ``f`` from a dynamic library ``lib`` and return it. Unlike ``PacletFunctionSet``, there is no mechanism
	by which to avoid eager loading of the default paclet library (i.e. there is no *LazyPacletFunctionLoad*). If ``lib`` is omitted, the dynamic library name
	is taken from the library given to ``InitializePacletLibrary``.

Supported options for all of the above functions include:

.. option:: "Optional" -> True | False

   Whether the library function is optional in the library, i.e. loading may fail quietly.  Defaults to **False**.

.. option:: "ProgressMonitor" -> None | _Symbol

   Provide a symbol which will store the current progress of library function. See :doc:`progress_monitor` for details. Defaults to **None**.

.. option:: "Throws" -> True | False

   Whether the library function should throw Failure expressions on error or return them as the result. Defaults to **True** (so Failures will be thrown).


Reducing boilerplate code
=============================

The set of utility functions described in the previous section allows you to reduce the amount of code you need to write in order to load functions from
your paclet's dynamic library to the Wolfram Language. Similarly, LLU provides a number of macros that eliminate the need to repeat the full signature
for every library function.

After you include `<LLU/LibraryLinkFunctionMacro.h>` instead of writing:

.. code-block:: cpp

	EXTERN_C DLLEXPORT int name (WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res);

you can type

.. doxygendefine:: LIBRARY_LINK_FUNCTION

And similarly instead of

.. code-block:: cpp

  EXTERN_C DLLEXPORT int name (WolframLibraryData libData, WSLINK wslp);

you can use

.. doxygendefine:: LIBRARY_WSTP_FUNCTION

Finally, if you use exception-based error handling you will often end up writing code like this:

.. code-block:: cpp
   :linenos:
   :emphasize-lines: 5

   EXTERN_C DLLEXPORT int name(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
       auto err = ErrorCode::NoError;
       try {
           LLU::MArgumentManager mngr {libData, Argc, Args, Res};
           // body of a function that effectively takes mngr as the single parameter
       } catch (const LibraryLinkError& e) {
           err = e.which();
       } catch (...) {
           err = ErrorCode::FunctionError;
       }
       return err;
   }

Fortunately, there is a macro that allows you to focus only on the highlighted part:

.. doxygendefine:: LLU_LIBRARY_FUNCTION


User-defined types
=====================

LibraryLink supports a number of types as function arguments and for the majority of use cases the built-in types are enough. However, imagine you are writing
a library that operates on financial data and it processes amounts of money. For example, in the Wolfram Language you work with expressions like
``Quantity[20.3, "USD"]`` and in C++ you have a corresponding structure:

.. code-block:: cpp

   struct Money {
       double amount;
       std::string currency;
   };

If you want to write a library function that takes an amount of money and a currency and converts that amount to the given currency, you will probably choose
``{Real, String, String}`` for argument types (``Quantity`` would be split into Real and String and the second String is for the new currency)
and ``"DataStore"`` for the return type. This requires some extra code on the Wolfram Language side to extract Real and String from the Quantity and
on the C++ side to construct a DataStore from a Money object. Having large number of functions in the library that may repeat those translations, you will
probably decide to factor this extra code to helper functions.

You could then use your library in Wolfram Language as follows:

.. code-block:: wolfram-language
   :force:

   (* Load raw library function that operates on basic LibraryLink types *)
   $ConvertMoney = LibraryFunctionLoad["myLib.so", "ConvertMoney", {Real, String, String}, "DataStore"];

   (* Create a higher-level wrapper for users of your package *)
   ConvertMoney[amount_Quantity, newCurrency_String] := With[
      {
         rawlibraryResult = $ConvertMoney[QuantityMagnitude[amount], QuantityUnit[amount], newCurrency];
      },
      $dataStoreToQuantity[rawLibraryResult]  (* $dataStoreToQuantity is a small utility function, omitted for brevity *)
   ];

   ConvertMoney[Quantity[50., "USD"], "PLN"]
   (* = Quantity[XXX, "PLN"] *)

The implementation of ``ConvertMoney`` in C++ would go along the lines:

.. code-block:: cpp

   EXTERN_C DLLEXPORT int ConvertMoney(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
       LLU::MArgumentManager mngr {libData, Argc, Args, Res};
       auto amount = mngr.get<double>(0);
       auto oldCurrency = mngr.get<std::string>(1);
       auto newCurrency = mngr.get<std::string>(2);

       auto moneyToConvert = Money { amount, oldCurrency };
       Money converted = myLib::convert(moneyToConvert, newCurrency);

       mngr.set(myLib::MoneyToDataList(converted));  // myLib::MoneyToDataList is a helper function to convert Money object to a DataList
       return LLU::ErrorCode::NoError;
   }


This is a fine code and if you are satisfied with it, you can stop reading here. However, it is possible with LLU to implement the same functionality like this:

.. code-block:: wolfram-language
   :force:

   (* Load "ConvertMoney" function from "myLib.so" and assign it to ConvertMoney symbol *)
   `LLU`PacletFunctionSet[ConvertMoney, "myLib.so", "ConvertMoney", {"Money", String}, "Money"];

   (* No need for separate higher-level wrapper because the types are translated by LLU now. *)

   ConvertMoney[Quantity[50., "USD"], "PLN"]
   (* = Quantity[XXX, "PLN"] *)

and in C++

.. code-block:: cpp

   EXTERN_C DLLEXPORT int ConvertMoney(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
       LLU::MArgumentManager mngr {libData, Argc, Args, Res};
       auto moneyToConvert = mngr.get<Money>(0);
       auto newCurrency = mngr.get<std::string>(2);  // under the hood Money object is still sent as two values (Real + String), so new currency has index 2

       Money converted = myLib::convert(moneyToConvert, newCurrency);

       mngr.set(converted);
       return LLU::ErrorCode::NoError;
   }

The point is to delegate the translation between your types and LibraryLink types to LLU, so that you can write cleaner code that does not distract readers
with technicalities.
To achieve this, you need to teach LLU to understand your types. Here is how you register ``"Money"`` as a library function argument type, the values of which
are of the form ``Quantity[_Real, _String]``:

.. code-block:: wolfram-language
   :force:

   `LLU`MArgumentType["Money", {Real, String}, (Sequence[QuantityMagnitude[#], QuantityUnit[#]]) &];

The second argument is the list of basic LibraryLink types that constitute to a single expression of type ``"Money"``. The third argument is a translation
function that takes something of the form ``Quantity[_Real, _String]`` and produces a ``Sequence`` of two values: Real and String.

In the C++ code we used ``mngr.get<Money>``, which means we have to tell LLU how many and what basic LibraryLink types correspond to a ``Money`` object.
This is achieved by defining a specialization of ``CustomType`` structure template and providing a type alias member ``CorrespondingTypes`` which must be a
``std::tuple`` of corresponding basic LibraryLink types:

.. code-block:: cpp

   template<>
   struct LLU::MArgumentManager::CustomType<Money> {
      using CorrespondingTypes = std::tuple<double, std::string>;
   };

With this information, whenever LLU is requested to read an argument of type ``Money`` it will read two
consecutive input arguments as ``double`` and ``std::string``, respectively, and construct a ``Money`` object from those 2 values.

In many cases this is sufficient, however in some situations you may want to have full control over how LLU creates objects of your type. Imagine we want
to always capitalize the currency that is passed from Wolfram Language code, before creating a ``Money`` object. To have such fine-grained control over
MArgumentManager's behavior, we must additionally specialize a struct template ``Getter`` that provides a member function ``get``, like this:

.. code-block:: cpp

   template<>
   struct LLU::MArgumentManager::Getter<Money> {
      static Money get(const MArgumentManager& mngr, size_type index) {
         auto [amount, currency] = mngr.getTuple<double, std::string>(index);
         std::transform(currency.begin(), currency.end(), currency.begin(), [](unsigned char c){ return std::toupper(c); });
         return Money { amount, std::move(currency) };
      }
   };

At this point, LLU knows how to change WL expressions of the form ``Quantity[_Real, _String]`` into ``Money`` objects in C++. The only thing left is to teach
LLU how to work in the other direction, i.e. how to return ``Money`` objects via "DataStore" and change them into Quantity. First, let us specialize
``MArgumentManager::set`` template:

.. code-block:: cpp

    template<>
    void LLU::MArgumentManager::set<Money>(const Money& m) const {
        DataList<NodeType::Any> moneyDS;
        moneyDS.push_back(m.amount);
        moneyDS.push_back(m.currency);
        set(moneyDS);
    }

You can read more about :cpp:class:`DataList <template\<typename T> LLU::DataList>` in the section
about :doc:`containers`. The last step is to tell LLU how to turn incoming DataStores into Quantities in library functions that declare "Money" as return type:

.. code-block:: wolfram-language
   :force:

   `LLU`MResultType["Money", "DataStore", (Quantity @@ #)&];

Here we say that if a library function has return type "Money", then the corresponding LibraryLink type is "DataStore" and when we get such a DataStore
we need to apply a function ``(Quantity @@ #)&`` to turn it into the form that we use to represent Money expressions.

Registering user-defined types in LLU may seem like a lot of extra work, but actually it is no extra work at all. It is merely a way to organize the code
that you would previously have written anyway in the form of small utility functions scattered all over your library and possibly even duplicated,
if you are not careful enough.

API reference
================

.. doxygenclass:: LLU::MArgumentManager
   :members:
