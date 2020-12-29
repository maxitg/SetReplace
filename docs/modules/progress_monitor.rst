.. include:: ../globals.rst

===========================================
Progress monitor
===========================================

When a :term:`library function` is executed in a Wolfram Language session, the Kernel will wait until the function returns. There is usually no real-time
feedback about function progress. :term:`LibraryLink` offers the `AbortQ <https://reference.wolfram.com/language/LibraryLink/ref/callback/AbortQ.html>`_
function which allows developers to correctly handle cases when the user aborts a library function execution. The drawback is that it is entirely up to library
developers to use ``AbortQ`` manually. The library must still return even when ``AbortQ`` returns ``true``, so there is still no guarantee that the execution
will end immediately upon an abort.

In practice, using time-consuming, non-abortable library functions often looks like this:

.. image:: ../_static/img/LibFunNoProg.gif
   :alt: Using non-abortable library function without progress monitor.

:term:`LLU` provides a class :cpp:class:`LLU::ProgressMonitor` which uses a 1-element shared tensor to report progress to Wolfram Language during
library function execution. The value in the tensor is a real number between 0.0 and 1.0 which indicates current progress of the function. It can be
increased/decreased by a given step (using convenient increment/decrement operators) or set to arbitrary value.
(Yes, decreasing progress may be useful sometimes too.)
Progress value can be read in the Kernel and displayed in the Front End for example as a progress bar.

As with many LLU features, the ``ProgressMonitor`` implementation consists of two parts: one in the library and one in Wolfram Language code. The goal is
to have decent functionality with minimal effort on the programmer's side.

In C++, the only thing you have to do is to get an instance of ProgressMonitor from MArgumentManager.

.. code-block:: cpp

   auto pm = mngr.getProgressMonitor();

``ProgressMonitor`` class also defines a method :cpp:func:`LLU::ProgressMonitor::checkAbort` which checks if the user has requested to abort current computation
and if so, throws an exception. It's a static function, so even if you don't own a ``ProgressMonitor`` instance, you can still check for aborts.
Calling ``checkAbort()`` also has a significant side-effect: it gives some CPU time to the Kernel in the middle of library function evaluation
and this may be helpful in updating the ``Dynamic`` which moves the progress bar in Front End.

The Wolfram Language implementation is minimal and basic. When you load an LLU function which uses ``ProgressMonitor`` with ``PacletFunctionSet`` or similar,
you have to pass an option :wl:`"ProgressMonitor" -> x`, where ``x`` is a Symbol.

Every time your library function reports progress, the new progress value will be assigned to ``x``. If and how the progress is visualized
in the notebook is completely up to the developer. Using a :wl:`ProgressIndicator` or :wl:`ComputeWithProgress` from :wl:`GeneralUtilities` is recommended.

The final effect may look like this (the second function call is aborted with a keyboard shortcut (by default :kbd:`Alt+.` on Linux)):

.. image:: ../_static/img/LibFunWithProg.gif
   :alt: Using abortable library function with simple progress bar.

Example
=========================

Consider a simple function that just sleeps in a loop moving the progress bar in a steady pace. This function takes two arguments:

 1. (Real) Total time (in seconds) for the function to complete
 2. (ProgressMonitor) Shared instance of an MTensor automatically wrapped in ProgressMonitor by MArgumentManager

.. code-block:: cpp
   :linenos:

   EXTERN_C DLLEXPORT int UniformProgress(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res) {

      // Create MArgumentManager to manage all the input and output arguments for the library function
      LLU::MArgumentManager mngr(libData, Argc, Args, Res);

      // Get first argument which determines how many seconds should this function take to evaluate
      auto totalTime = mngr.getReal(0);

      // Calculate number of steps for the progress bar, we want 10 steps per second
      auto numOfSteps = static_cast<int>(std::ceil(totalTime * 10));

      // Get ProgressMonitor instance, initialize with the number of seconds per step
      auto pm = mngr.getProgressMonitor(1.0 / numOfSteps);

      // Sleep in a loop, increase progress in each iteration. Increasing progress also automatically checks for Abort.
      for (int i = 0; i < numOfSteps; ++i) {
         std::this_thread::sleep_for(100ms);
         ++pm;
      }

      // Set function result and return
      mngr.setInteger(42);
      return LLU::ErrorCode::NoError;
   }

For progress reporting to work on the Wolfram Language side as expected, the library function must be loaded with extra option "ProgressMonitor", like this:

.. code-block:: wolfram-language

   `LLU`PacletFunctionSet`[UniformProgress, "UniformProgress", {Real}, Integer, "ProgressMonitor" -> MyPaclet`PM`UniformProgress];

By default, :wl:`"ProgressMonitor" -> None` is used.
It's a good idea to make sure the name for the monitoring symbol will be unique. One suggestion is to use ``PacletName`PM`` as the context, and the name of the
symbol to be the same as the function name.

Now, run your library function with simple progress bar:

.. code-block:: wolfram-language

   Monitor[
      UniformProgress[5],
      ProgressIndicator[Dynamic @ First @ Refresh[MyPaclet`PM`UniformProgress, UpdateInterval -> 0.2]]
   ]

API reference
=========================

.. doxygenclass:: LLU::ProgressMonitor
	:members:
