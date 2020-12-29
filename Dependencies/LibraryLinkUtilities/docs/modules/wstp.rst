===================
WSTP support
===================

LibraryLink allows a LinkObject to be passed as an argument which may then exchange data between your library and the Kernel using
Wolfram Symbolic Transfer Protocol (**WSTP**, also known as **MathLink**).
The original WSTP is a C style API with error codes, macros, manual memory management, etc.
LLU provides a wrapper for the LinkObject called ``WSStream``.

``WSStream`` is actually a class template in the namespace ``LLU`` parameterized by the default encodings to be used for strings, but for the sake of clarity,
both the template parameters and the namespace are skipped in the remainder of this text.


Main features
====================

Convenient syntax
-----------------------

In LLU WSTP is interpreted as an I/O stream, so operators << and >> are utilized to make the syntax cleaner and more concise.
This frees developers from the responsibility to choose the proper WSTP API function for the data they intend to read or write.

Error checking
-----------------------

Each call to WSTP API has its return status checked. An exception is thrown on failures which carries some debug info to help locate the problem.
Sample debug info looks like this::

	Error code reported by WSTP: 48
	"Unable to convert from given character encoding to WSTP encoding"
	Additional debug info: WSPutUTF8String


Memory cleanup
-----------------------

WSRelease* no longer needs to be called on the data received from WSTP. The LLU framework does it for you.

Automated handling of common data types
--------------------------------------------------

Some sophisticated types can be sent to Wolfram Language directly via a WSStream class. For example nested maps:

.. code-block:: cpp

	std::map<std::string, std::map<int, std::vector<double>>> myNestedMap


Just write `ms << myNestedMap` and a nested Association will be returned. It works in the other direction too.
Obviously, for the above to work, the key and value types in the map must be supported by WSStream (i.e. there must exist an overload of
``WSStream::operator<<`` that takes an argument of given type).

User-defined classes
----------------------------------------

Suppose you have a structure

.. code-block:: cpp

	struct Color {
	    double red;
	    double green;
	    double blue;
	};


It is enough to overload `operator<<` like this:

.. code-block:: cpp
   :linenos:
   :dedent: 1

	WSStream& operator<<(WSStream& ms, const Color& c) {
	    return ms << WS::Function("RGBColor", 3) << c.red << c.green << c.blue;
	}


Objects of class `Color` can now be sent directly via WSStream.


Example
=============

Let's compare the same piece of code written in plain LibraryLink with one written with LLU and WSStream. Here is the plain LibraryLink code:

.. code-block:: cpp
   :dedent: 1

	if (!WSNewPacket(mlp)) {
	    wsErr = -1;
	    goto cleanup;
	}
	if (!WSPutFunction(mlp, "List", nframes)) {
	    wsErr = -1;
	    goto cleanup;
	}
	for (auto& f : extractedFrames) {
	    if (!WSPutFunction(mlp, "List", 7)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutFunction(mlp, "Rule", 2)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutString(mlp, "ImageSize")) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutFunction(mlp, "List", 2)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutInteger64(mlp, f->width)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutInteger64(mlp, f->height)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    // ...
	    if (!WSPutFunction(mlp, "Rule", 2)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutString(mlp, "ImageOffset")) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutFunction(mlp, "List", 2)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutInteger64(mlp, f->left)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutInteger64(mlp, f->top)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    // ...
	    if (!WSPutFunction(mlp, "Rule", 2)) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutString(mlp, "UserInputFlag")) {
	        wsErr = -1;
	        goto cleanup;
	    }
	    if (!WSPutSymbol(mlp, f->userInputFlag == true ? "True" : "False")) {
	        wsErr = -1;
	        goto cleanup;
	    }
	}
	if (!WSEndPacket(mlp)) {
		/* unable to send the end-of-packet sequence to mlp */
	}
	if (!WSFlush(mlp)){
		/* unable to flush any buffered output data in mlp */
	}

and now the same code using WSStream:

.. code-block:: cpp
   :dedent: 1

	WSStream ms(mlp);

	ms << WS::NewPacket;
	ms << WS::List(nframes);

	for (auto& f : extractedFrames) {
	    ms << WS::List(7)
	        << WS::Rule
	            << "ImageSize"
	            << WS::List(2) << f->width << f->height
	        // ...
	        << WS::Rule
	            << "ImageOffset"
	            << WS::List(2) << f->left << f->top
	        // ...
	        << WS::Rule
	            << "UserInputFlag"
	            << f->userInputFlag
	}

	ms << WS::EndPacket << WS::Flush;


Expressions of unknown length
-----------------------------------------------

Whenever you send an expression via WSTP you have to first specify the head and the number of arguments. This is not very flexible
for example when an unknown number of contents are being read from a file.

As a workaround, one can create a temporary loopback link, accumulate all the arguments there (without the head),
count the arguments, and then send everything to the "main" link as usual.

The same strategy has been incorporated into WSStream so that developers do not have to implement it. Now you can send a `List` like this:

.. code-block:: cpp
   :linenos:
   :dedent: 1

	WSStream ms(mlp);

	ms << WS::BeginExpr("List");
	while (dataFromFile != EOF) {
		// process data from file and send to WSStream
	}
	ms << WS::EndExpr();


.. warning::

	This feature should only be used if necessary since it requires a temporary link and makes extra copies
	of data. Simple benchmarks showed a ~2x slowdown compared to the usual `WSPutFunction`.


API reference
================

.. doxygenclass:: LLU::WSStream
   :members:
