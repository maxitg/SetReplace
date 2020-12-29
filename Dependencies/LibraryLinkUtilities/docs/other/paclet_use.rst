====================================
Use in paclets
====================================

Submodule
=============================

In :doc:`../basic/how_to_use` you can learn how to build and install :term:`LLU` on your system and then use it as a dependent library for your Wolfram Language
paclets. There exists an alternative approach which is often quite convenient if you plan to work on multiple paclets that may use different versions of LLU.
This approach is to include LLU in a project as a git submodule. Submodules are simply git repos inside other repos but working with them may sometimes be
tricky. See this excellent `tutorial on submodules <https://git-scm.com/book/en/v2/Git-Tools-Submodules>`_.

For SourceTree users there is also a helpful `blog post <https://blog.sourcetreeapp.com/2012/02/01/using-submodules-and-subrepositories/>`_.

In most cases you will access LibraryLink Utilities in "read-only" manner, i.e. you will just update the submodule to make sure you use the most recent version.

Here is a list of commands that might be useful to developers who want to use LLU as a submodule. For the sake of example, assume that we have a sample paclet
with a directory :file:`CPPSource/` containing all the C++ source code and that we want to place the submodule in this directory.
It is easy to modify these commands so that they work for other locations too.

* Adding LibraryLink Utilities to your paclet

   .. code-block:: console

      git submodule add **TODO: Insert LLU clone link** CPPSource/LibraryLinkUtilities

* Cloning a project that already uses LibraryLink Utilities

   .. code-block:: console

      git clone --recursive <paclet's git clone link>

* Updating LibraryLink Utilities in your project

   .. code-block:: console

      git submodule update --remote CPPSource/LibraryLinkUtilities/

Submodules work in a "detached head" state which means they stick to a chosen commit, so even if there are backwards incompatible changes merged to LLU master
your project will not be affected unless you manually update the submodule.

With LLU attached to your project in a submodule you always have the sources so you only need to follow steps 2 - 4 described
:doc:`in the official build instructions<../basic/how_to_use>`.

Paclets that use LLU
==========================================================

If you look for examples of LLU usage and whatever is in this documentation and in the Demo project was not enough, you can take a look at paclets built into
the Wolfram Language that use LLU. You will not be able to see the C++ source code or the CMake build script but you can still investigate the paclet structure
and the Wolfram Language code. Paclets can be found in the :file:`SystemFiles/Links` subdirectory of your installation.

The list below may not be complete.

- ArchiveTools
- DICOMTools
- FFmpegTools
- SVTools
