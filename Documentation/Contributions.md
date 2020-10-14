# Getting Started

## Dependencies

You only need three things to use *SetReplace*:

* Windows, macOS 10.12+, or Linux.
* [Wolfram Language 12.1+](https://www.wolfram.com/language/) including [WolframScript](https://www.wolfram.com/wolframscript/). A free version is available as [Wolfram Engine](https://www.wolfram.com/engine/).
* A C++17 compiler to build the low-level part of the package. Instructions on how to set up a compiler to use in WolframScript are [here](https://reference.wolfram.com/language/CCompilerDriver/tutorial/SpecificCompilers.html#509267359).

## Build Instructions

To build:

1. `cd` to the root directory of the repository.
2. Run `./build.wls` to create the paclet file. If you see an error message about c++17, make sure the C++ compiler you are using is up-to-date. If your default system compiler does not support c++17, you can choose a different one with environmental variables. The following, for instance, typically works on a Mac:

    ```bash
    COMPILER=CCompilerDriver\`ClangCompiler\`ClangCompiler COMPILER_INSTALLATION=/usr/bin ./build.wls
    ```

    Here `ClangCompiler` can be replaced with one of ``<< CCompilerDriver`; "Compiler" /. CCompilerDriver`CCompilers[Full]``, and `COMPILER_INSTALLATION` is a directory in which the compiler binary can be found.

3. Run `./install.wls` to install the paclet into your Wolfram system.
4. Evaluate `PacletDataRebuild[]` in all running Wolfram kernels.
5. Evaluate ``<< SetReplace` `` every time before using the package.

A less frequently updated version is available through the Wolfram public paclet server and can be installed with `PacletInstall["SetReplace"]`.

## Contributing

Keep in mind that this is an active research project. While we try to keep the main functionality backward compatible, it might change in the future as we adjust our models and find better ways of analysis. Keep that in mind when building on top of *SetReplace*, and keep track of [git SHAs](UtilityFunctions.md#build-data) as you go.

*SetReplace* is an open-source project, and everyone is welcome to contribute. Read our [contributing guidelines](/.github/CONTRIBUTING.md) to get started.

We have a [Discord server](https://discord.setreplace.org). If you would like to contribute but have questions or don't know where to start, this is the perfect place! In addition to helping new contributors, we discuss feature and research ideas. So, if you are interested, please join!