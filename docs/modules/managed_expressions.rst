======================
Managed expressions
======================

One of the features offered by LibraryLink is Managed Library Expressions (MLEs). The idea is to create C/C++ objects
that will be automatically deleted when they are no longer referenced in the Wolfram Language code. More information can
be found in the official LibraryLink `documentation <https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage.html#353220453>`_.

This allows for an object-oriented programming paradigm and it is the recommended way of referencing
C++ objects from the Wolfram Language. The two most notable alternatives are:

* recreating C++ objects every time a library function is called

* maintaining some sort of global cache with referenced objects, where each object is added on first use and manually deleted at some point.

LLU uses methods similar to the second alternative to facilitate using MLEs and decrease the amount of boilerplate
code needed from developers. Namely, for each class that you register to be used as MLE, LLU will maintain a map, which
associates managed C++ objects with IDs assigned to them by the Wolfram Language.

Register a class as Managed Expression
=========================================

Imagine you have a class `A` whose objects you want to manage from the Wolfram Language:

.. code-block:: cpp

   struct A {
      A(int n) : myNumber{n} {}
      int getMyNumber() const { return myNumber; }
   private:
      int myNumber;
   };

Then you must create the corresponding Store and specialize a callback function for LibraryLink (this is a technicality
that just needs to be done):

.. code-block:: cpp

   LLU::ManagedExpressionStore<ClassName> AStore;  //usually <class name>Store is a good name

   //specialize manageInstanceCallback, this should just call manageInstance function from your Store
   template<>
   void LLU::manageInstanceCallback<A>(WolframLibraryData, mbool mode, mint id) {
      AStore.manageInstance(mode, id);
   }

.. doxygenfunction:: LLU::manageInstanceCallback

Alternatively, you can use a macro:

.. doxygendefine:: DEFINE_MANAGED_STORE_AND_SPECIALIZATION

but the macro has some limitations:

1. it must be invoked from the global namespace
2. the definition of ``ClassName`` must be visible at the point of invocation
3. ``ClassName`` must be an unqualified name (which combined with 1. means that ``ClassName`` must be a class defined in the global namespace)

Lastly, you need to register and unregister your type when library gets loaded or unloaded, respectively.

.. code-block:: cpp
   :linenos:

   EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
      LLU::LibraryData::setLibraryData(libData);
      AStore.registerType("A");   // the string you pass is the name of a symbol that will be used in the Wolfram Language for managing
      return 0;                   // objects of your class, it is a good convention to just use the class name
   }

   EXTERN_C DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData) {
      AStore.unregisterType(libData);
   }

With MLEs in LibraryLink it is not possible to pass arguments for construction of managed expressions.
LLU extends the MLE implementation by letting the developer define a library function that LLU will call from the Wolfram Language
when a new instance of a managed expression is created. In other words, define a wrapper for constructor of your class.
Typically, it will look like this:

.. code-block:: cpp
   :linenos:

   EXTERN_C DLLEXPORT int OpenManagedA(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {
      auto err = LLU::ErrorCode::NoError;
      try {
         LLU::MArgumentManager mngr(libData, Argc, Args, Res);
         auto id = mngr.getInteger<mint>(0); // id of the object to be created
         auto arg1 = mngr.getXXXX(1);
         auto arg2 = mngr.getYYYY(2);
         ... // read the rest of parameters for constructor of your managed class
         AStore.createInstance(id, arg1, arg2, ...);
      } catch (const LLU::LibraryLinkError& e) {
         err = e.which();
      }
      return err;
   }


It is simpler to register an MLE in the Wolfram Language. You only need to load your constructor wrapper:

.. code-block:: wolfram-language

   `LLU`Constructor[A] = `LLU`PacletFunctionLoad["OpenManagedA", {`LLU`Managed[A], Arg1Type (*, ...*)}, "Void"];



Using Managed Expressions
=========================================

After the registration is done, using MLEs is very simple. In C++ code, MLEs can be treated as another MArgument type,
for example let's define a wrapper library function over ``A::getMyNumber()``:

.. code-block:: cpp
   :linenos:

   LIBRARY_LINK_FUNCTION(GetMyNumber) {
      auto err = LLU::ErrorCode::NoError;
      try {
         // create an instance of MArgumentManger for this function
         LLU::MArgumentManager mngr {Argc, Args, Res};

         // get a reference to the Managed Expression of type A, on which this function was called in the Wolfram Language
         const A& myA = mngr.getManagedExpression(0, AStore);

         // set the value of myA.getMyNumber() as the result of this library function
         mngr.set(myA.getMyNumber());

      } catch (const LLU::LibraryLinkError &e) {
         err = e.which();
      }
      return err;
   }

In the Wolfram Language, wrappers over member functions can be conveniently loaded:

.. code-block:: wolfram-language

   `LLU`LoadMemberFunction[A][
      getMyNumber,      (* fresh symbol for the member function *)
      "GetMyNumber",    (* function name in the library *)
      {},               (* argument list *),
      Integer           (* result type *)
   ];


The only thing left now is to create an MLE instance and call the member function on it:

.. code-block:: wolfram-language

   myA = `LLU`NewManagedExpression[A][17];

   myA @ getMyNumber[]
   (* = 17 *)


API Reference
=========================================

.. doxygenclass:: LLU::ManagedExpressionStore
   :members:
