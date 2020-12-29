.. include:: ../globals.rst

=====================
Error handling
=====================

On the C++ side
~~~~~~~~~~~~~~~~

Every LibraryLink function in C or C++ code has a fixed signature [#]_

.. code-block:: cpp

   int f (WolframLibraryData libData, mint Argc, MArgument* Args, MArgument Res);

The actual result of computations should be returned via the "out-parameter" ``Res``. The value of ``Res`` is only considered in the Wolfram Language code if the actual
return value of ``f`` (of type ``int``) was equal to ``LIBRARY_NO_ERROR`` (with LLU use ``ErrorCode::NoError``, see note below).

.. tip::
   LibraryLink uses 8 predefined error codes

   .. code-block:: cpp

      enum {
          LIBRARY_NO_ERROR = 0,
          LIBRARY_TYPE_ERROR,
          LIBRARY_RANK_ERROR,
          LIBRARY_DIMENSION_ERROR,
          LIBRARY_NUMERICAL_ERROR,
          LIBRARY_MEMORY_ERROR,
          LIBRARY_FUNCTION_ERROR,
          LIBRARY_VERSION_ERROR
      };

   LLU redefines those values as constexpr integers in a dedicated namespace :cpp:any:`LLU::ErrorCode`, so for example instead of
   ``LIBRARY_FUNCTION_ERROR`` one can use :cpp:any:`ErrorCode::FunctionError`.


In C++, exceptions are often the preferred way of error handling, so LLU offers a special class of exceptions that can be easily translated to error codes,
returned to LibraryLink and then translated to descriptive :wlref:`Failure` objects in the Wolfram Language.

Such exceptions are identified in the C++ code by name - a short string. For example, imagine you have a function that reads data from a source.
If the source does not exist or is empty, you want to throw exceptions, let's call them "NoSourceError" and "EmptySourceError", respectively.
First, you **must** register all your exceptions inside ``WolframLibrary_initialize`` function:

.. code-block:: cpp
   :linenos:

   EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
       try {
           LibraryData::setLibraryData(libData);
           ErrorManager::registerPacletErrors({
               {"NoSourceError", "Requested data source does not exist."},
               {"EmptySourceError", "Requested data source has `1` elements, but required at least `2`."}
           });
       } catch(...) {
           return LLErrorCode::FunctionError;
       }
       return LLErrorCode::NoError;
   }

In the code above, the second element of each pair is a textual description of the error which will be visible in the :wlref:`Failure` object.
This text may contain "slots" denoted as \`1\`, \`2\`, etc. that work like :wlref:`TemplateSlot` in the Wolfram Language.

.. note::
   Notice that there is no way to assign specific error codes to your custom exceptions, this is handled internally by LLU.

Now, throw exceptions from a function that reads data:

.. code-block:: cpp
   :linenos:

   void readData(std::unique_ptr<DataSource> source) {
       if (!source) {
           ErrorManager::throwException("NoSourceError");
       }
       if (source->elemCount() < 3) {
           ErrorManager::throwException("EmptySourceError", source->elemCount(), 3);
       }
       //...
   }

Each call to :cpp:func:`ErrorManager::throwException<LLU::ErrorManager::throwException>` causes an exception of class :cpp:class:`LibraryLinkError<LLU::LibraryLinkError>`
with predefined name and error code to be thrown.
All parameters of :cpp:func:`throwException<LLU::ErrorManager::throwException>` after the first one are used to populate consecutive template slots in the error message.
The only thing left to do now is to catch the exception.
Usually, you catch only in the interface functions (the ones with ``EXTERN_C DLLEXPORT``), extract the error code from exception and return it:

.. code-block:: cpp
   :linenos:

   EXTERN_C DLLEXPORT int MyFunction(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
       auto err = ErrorCode::NoError;    // no error initially
       try {
           //...
       } catch (const LibraryLinkError& e) {
           err = e.which();    // extract error code from LibraryLinkError
       } catch (...) {
           err = ErrorCode::FunctionError;   // to be safe, handle non-LLU exceptions as well and return generic error code
       }
       return err;
   }

On the Wolfram Language side
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Wolfram Language part of the error-handling functionality of LLU is responsible for converting error codes returned by library functions
into nice and informative :wlref:`Failure` objects. Whether these objects will be *returned* or *thrown* on the WL side is determined by the ``"Throws"`` option
specified when loading a library function with LLU:

.. code-block:: wolfram-language

   (* This must go first, see the "How to use" -> "Add to your project" section *)
   `LLU`InitializePacletLibrary["/path/to/my/library"];

   `LLU`PacletFunctionSet[$MyThrowingFunction, "FunctionNameInCppCode", {Integer, String}, Integer] (* by default, "Throws" -> True *)

   `LLU`PacletFunctionSet[$MyNonThrowingFunction, "OtherFunctionNameInCppCode", {"DataStore"}, "DataStore", "Throws" -> False]


This code will first load the paclet's dynamic library located under :file:`/path/to/my/library` and then it will load exported functions in the library named
``FunctionNameInCppCode`` and ``OtherFunctionNameInCppCode`` into :wlref:`LibraryFunction` expressions and assign them to symbols ``$MyThrowingFunction`` and
``$MyNonThrowingFunction``, respectively.

If any call to ``$MyThrowingFunction`` fails (returns an error code different than :cpp:any:`LLU::ErrorCode::NoError`) a corresponding Failure expression will
be *thrown*, whereas ``$MyNonThrowingFunction`` will *return* the Failure.

Apart from the C++ code, paclets often have nontrivial amount of Wolfram Language code where errors might also occur. In order to achieve uniform
error reporting across C++ and WL, one needs to register errors specific to the WL layer of the paclet:

.. code-block:: wolfram-language

   `LLU`RegisterPacletErrors[<|
      "InvalidInput" -> "Data provided to the function was invalid.",
      "UnexpectedError" -> "Unexpected error occurred with error code: `errCode`."
   |>];

``RegisterPacletErrors`` takes an :wlref:`Association` of user-defined errors of the form

   error_name -> error_message

Such registered errors can later be issued from the Wolfram Language part of the project like this:

.. code-block:: wolfram-language

   status = DoSomething[input];
   If[Not @ StatusOK[status],
      `LLU`ThrowPacletFailure["UnexpectedError", "MessageParameters" -> <|"errCode" -> status|>]
   ]

This code will throw a ``Failure`` expression of the following form:

.. code-block:: wolfram-language
   :caption: Sample Failure thrown from paclet code
   :name: sample-failure

   Failure["UnexpectedError", <|
      "MessageTemplate" -> "The error `errCode` has not been registered.",
      "MessageParameters" -> <|"errCode" -> status|>,
      "ErrorCode" -> 23,   (* assigned internally by LLU, might be different *)
      "Parameters" -> {}
   |>]

.. important::
   It is important to remember that all Failures thrown by ```LLU`ThrowPacletFailure`` have a *tag* (second argument to :wlref:`Throw`),
   so when writing code that is supposed to catch exceptions issued by LLU one must always use 2- or 3-argument version of :wlref:`Catch`.

The exact value of the *tag* used by LLU is ```LLU`$ExceptionTagFunction[f]``, where ``f`` is the :wlref:`Failure` object to be thrown.
In other words, the *tag* can be any function of the Failure object and developers are encouraged to customize this behavior.

By default, ``$ExceptionTagFunction`` is a constant function that returns ``$ExceptionTagString`` which is initially set to "LLUExceptionTag":

.. code-block:: wolfram-language

   $ExceptionTagString = "LLUExceptionTag";
   $ExceptionTagFunction := $ExceptionTagString&;

In case you want Failures from your paclet to be thrown with a predefined String tag, say, "MyPacletError", it is enough to write

.. code-block:: wolfram-language

   `LLU`$ExceptionTagString = "MyPacletError";

If you want to the tag to be different for different kinds of Failures, you may want to do something like this:

.. code-block:: wolfram-language

   `LLU`$ExceptionTagFunction = ("MyPaclet_" <> First[#])&;

This will effectively prefix Failure's tag with "MyPaclet\_", so for instance for the Failure from listing :ref:`sample-failure` the tag will be
"MyPaclet_UnexpectedError".

There exists an alternative to ```LLU`ThrowPacletFailure`` called ``LLU`CreatePacletFailure`` which returns the Failure expression as the result instead of
throwing it.

API reference
~~~~~~~~~~~~~~~~~

.. doxygennamespace:: LLU::ErrorCode

--------------------------

.. doxygenclass:: LLU::LibraryLinkError
   :members:

---------------------------

.. doxygenclass:: LLU::ErrorManager
   :members:


.. rubric:: Footnotes
.. [#] One more possible signature is ``int f(WolframLibraryData, WSLINK)``. For such functions error handling is done in the same way.