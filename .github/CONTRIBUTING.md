[![Discord](https://img.shields.io/discord/761616685173309481?logo=Discord)](https://discord.setreplace.org)

First, thanks for contributing! :thumbsup:

These are the guidelines designed to make the development smooth, efficient, and fun for all of us. But remember, we are the ones who write them, and *anybody* is welcome to propose changes. Just open a pull request.

There are fundamentally three kinds of things you can contribute: [issues](#issues) ([reports](#weed-reports-something-is-not-working) and [ideas](#feature-suggestions)), [code](#code), and [research notes](#research).

# Issues

## Weed reports (something is not working)

First off, while it's common to call problems with the code "bugs", we call them *weeds* here instead (kudos to [@aokellermann](https://github.com/aokellermann)). That's because using the word "bug" in a negative context implicitly sends a message that *bugs* (aka insects) are someone bad and should be squashed. We don't agree with that sentiment, as *bugs* :ant: :beetle: :spider: are living creatures who deserve moral consideration. Hence, let's leave "bugs" alone, and go *weed whacking*.

The issues in this repository are only related to *SetReplace*, not the entire Wolfram Physics Project. If you have found an issue with a Wolfram Physics [bulletin](https://www.wolframphysics.org/bulletins/), or with anything else on the Wolfram Physics [website](https://www.wolframphysics.org), please report it using the tools available there. The bulletins that also appear as [research notes](/Research) in this repository are the only exceptions. The issues with these should be reported here.

Similarly, the weeds in function repository functions should be reported on the function repository website rather than here.

To report a weed, follow these steps:
1. Go to the [Issues page](https://github.com/maxitg/SetReplace/issues), and use the search to check if the weed you have encountered is in the list already. If it is, and it was not getting much attention lately, the best you can do is to comment that you care about it being fixed, and to leave the example you have encountered that's not working (if it's not similar to ones already there).
2. If the weed is not in the list, click "New issue", and then "Get started" next to the "Weed report".
3. Fill in all the fields including:
  * Brief description in natural language.
  * The line of Wolfram Language code that results in unexpected behavior (or a screenshot if the weed is in the UI).
  * The actual output you are getting.
  * The output you expect to see.
  * The output of `SystemInformation["Small"]` and `$SetReplaceGitSHA`.
  * If the weed appears randomly and is not easy to reproduce, add details about how often and in what circumstances you encounter it.
4. If you have a Mathematica notebook with more details, you can attach it to the issue, just compress it to a `ZIP` file first.
5. Click "Submit new issue".
6. Your issue is now on the list, and a developer will look at it if/when they have a chance. But if it does not get any attention, the best you can do is to [fix it yourself](#code).

Also, please understand that mistakes happen and are unavoidable. We never blame people for unintentional mistakes in this project. Instead, we improve our development process to minimize the probability of mistakes in the future.

## Feature suggestions

If you have an idea to improve an existing function, add a property to `WolframModel`, or add a new function that does not currently exist, you can suggest it by creating a feature request. There are no guarantees, but someone might implement it if they like the idea. You are welcome to suggest research ideas as long as they are directly related to the models implemented in *SetReplace*.

The process is similar to weed reports, just use the "Feature request" option instead. Don't include any version information in feature requests.

## Labels

It is helpful to add [labels](https://github.com/maxitg/SetReplace/labels) to your issue. This makes it easier for developers to find something they are interested in and comfortable working with. We have several categories of labels corresponding to different colors.

First, assign one of the *type* labels to your pull request:
* `feature`: new functionality, or change in existing functionality.
* `weed`: fixes something that was not working.
* `test`: adds new tests for existing functionality.
* `documentation`: adds or changes documentation for existing functionality.
* `optimization`: does not change functionality but makes code faster.
* `convenience`: makes the syntax more convenient without significantly changing functionality.
* `design`: changes the visual design (styles, colors, icons, etc.) without affecting functionality.
* `refactor`: does not change functionality, but makes the code better organized or more readable.
* `research`: introduces new ideas about the structure of the models themselves ([research notes](#research) will typically have this label).

Then, assign one of the *component* labels:
* `evolution`: modifies code for running the evolution of the model.
* `analysis`: adds or changes evolution analysis tools, e.g., `WolframModelEvolutionObject` properties.
* `visualization`: has to do with visualization code, such as `WolframModelPlot`.
* `physics`: explores a connection with known physics. Would typically only be used with some `research` notes.
* `utilities`: implements a tool that does not fit in the above categories (e.g., [`Subhypergraph`](https://github.com/maxitg/SetReplace/pull/431)).
* `infrastructure`: implements changes to the development process, e.g., build scripts, CI, testing utilities, etc.

It is also helpful to specify the language one expects to use to solve the issue. This helps developers to find issues they are comfortable working with. The current choices are `c++`, `wolfram language`, and `english` (e.g., for research documents).

Also, one of the following may be used:
* `critical`: fixes something that severely breaks the package (usually used for weeds).
* `breaking`: introduces API changes that would break existing code, better to avoid if possible.
* `blocked`: another issue needs to be closed before this one can be started. If using this label, you need to mention the blocking issue in the description.

# Code

If you would like to contribute code, thanks again! :tada: :balloon: :tada:

In the sections below, we describe our [development process](#development-process), [the code structure](#code-structure), and [our code style rules](#code-style). However, if you are unsure about something, don't let these rules deter you from opening pull requests! If something is missing, or if there are issues with the code style, someone will help you fix them during code review.

## Development process

Each change to the code must fundamentally pass through 5 steps, more or less in that order: [writing code](#writing-code), [opening a pull request](#opening-a-pull-request), passing [automated tests](#automated-tests), passing [code review](#code-review), and [merging the PR](#merging).

### Writing code

In addition to the code itself, each pull request should include unit tests and documentation.

To help you get started, see how the code is [organized](#code-structure) and our notes on [code style](#code-style). Also, we are keeping dependencies to a minimum to make the paclet as easy to compile and run as possible. So, avoid adding dependencies if at all possible. That includes Wolfram Function Repository functions. Even though they don't require installation, most of them are not stable enough for use in *SetReplace*. Also, using them may result in unexpected behavior as they can be updated independently of *SetReplace*, and there is no way to enforce a specific version. They also require an Internet connection in a way that's hard to control. If you still think adding a dependency is worth it, please open a feature request first to discuss it. If you need functionality from a resource function, you are always welcome to add the function to *SetReplace*, but you will have to improve it to follow the same quality standards as the rest of the code.

The unit tests are particularly important if you are implementing a weed fix, as it is crucial to make sure the weed you are fixing is not going to return in the future. And if you are implementing a new function, unit tests should cover not only the functionality but also the behavior in case the function is called with invalid arguments. Each function should have at least some unit tests; there is a test in [meta.wlt](/Tests/meta.wlt) to enforce that.

If sharing variables among multiple tests, use [`With`](https://reference.wolfram.com/language/ref/With.html) instead of [`Module`](https://reference.wolfram.com/language/ref/Module.html) or global assignment, because otherwise, variables will not appear resolved in the command line error message if the test fails (which makes it harder to weed whack). Also, try to avoid large inputs and outputs for the tests, if at all possible (by, for example, replacing `VerificationTest[large1[], large2[]]` with `VerificationTest[large1[] === large2[]]`).

You should also modify the [README](/README.md) or the corresponding files in the Documentation directory if you are implementing new functionality, or causing any outputs there to change.

**Never put notebooks (.nb files) in the repository**, as they, even though text files, are not human readable, cannot be reviewed line-by-line, and are guaranteed to cause conflicts, which would be almost impossible to resolve. In fact, `.nb` files are listed in the `.gitignore` file precisely so that you cannot accidentally add them.

### Opening a pull request

Each pull request message should include detailed information on what was changed, optional comments for the reviewer, and **examples**, including screenshots if the output is a [`Graphics`](https://reference.wolfram.com/language/ref/Graphics.html) object. If your pull request closes an existing issue (as it generally should, as it's best to discuss your changes before implementing them), reference that issue in your pull request message. For an example of a good pull request message, see [#268](https://github.com/maxitg/SetReplace/pull/268).

Next, assign the labels. The convention for labels is the same as for [issues](#labels), and usually, labels will be the same as in the issue the pull request is closing or working toward.

Next, assign a reviewer to your pull request. Ideally, it should be someone who has recently edited the same files. If in doubt, assign to [@maxitg](https://github.com/maxitg).

It is essential to keep your pull requests as small as possible (definitely under 1000 lines, preferably under 500 lines). Keeping them small streamlines the review process and makes it more likely your changes will find their way into master, as it's always possible you will get distracted and won't be able to finish one giant pull request. It also helps keep your pull requests up-to-date with master, which is useful because master's changes might introduce conflicts or break your code.

### Automated tests

To run the tests, `cd` to the repository root, and run `./build.wls && ./install.wls && ./test.wls` from the command line. If everything is ok, you will see `[ok]` next to each group of tests, and "Tests passed." message at the end. Otherwise, you will see error messages telling you which test inputs failed and for what reason.

The `test.wls` script accepts various arguments. Running `./test.wls testfile`, where `testfile` is the name (without trailing `.wlt`) of a test file under the `Tests` directory, will limit the test run to only that file. With the `--load-installed-paclet` flag, the script will load the *installed paclet* instead of the local codebase. With the `--disable-parallelization` flag, you can disable the use of parallel sub-kernels to perform tests. Using parallel sub-kernels will accelerate running the entire test suite, so it is the default behavior, but if you are running only a single test file with a small number of tests, the startup time of the sub-kernels can outweight any speedup they give, and so `--disable-parallelization` will improve performance.

We have a CI that automatically runs tests for all commits on all branches (kudos to [Circle CI](https://circleci.com) for providing free resources for this project). You need collaborator access to run the CI. If you don't have such access yet, the reviewer will run it for you.

We use a private docker image `maxitg/set-replace:ci` running *Ubuntu* and *Wolfram Engine*, which [runs](https://app.circleci.com/pipelines/github/maxitg/SetReplace/408/workflows/8577ff51-2f5a-4517-992c-b20c76dcf170/jobs/444) [build](/build.wls), [install](/install.wls) and [test](/test.wls) scripts.

Your code must successfully pass all tests to be mergeable to master.

We also have a setup within Wolfram Research that allows us to build the paclet containing compiled binary libraries for all platforms, which we use for releases, but it's only available to developers working in the company. If you need such paclet for a version that is not a current release, please contact [@maxitg](https://github.com/maxitg).

In addition to correctness tests, we have a performance testing tool, which is currently in the early stage of development, and only allows testing of the performance of the evolution. To use it, run in the repository root:

```bash
./performanceTest.wls oldCommit newCommit testCount
```

Here `oldCommit` and `newCommit` are the git SHAs or branch names which should be compared, and `testCount` determines how many times to run each test for averaging (higher numbers decrease errors proportional to the square root, but take linearly longer to evaluate).

A short-hand syntax is available as well, specifically, `./performanceTest.wls oldCommit newCommit` runs each test 5 times, `./performanceTest.wls oldCommit` compares the `HEAD` to the `oldCommit`, and `./performanceTest.wls` compares the `HEAD` to `master`.

The tool will checkout other branches while testing, so don't use git/modify any files while it's running. Results depend on the other activity happening on the machine, so do not perform any CPU-intensive tasks while running tests to avoid introducing bias to the results.

As an example, test an optimization done to *libSetReplace* by [@aokellermann](https://github.com/aokellermann):

```
> ./performanceTest.wls db6f15c7b4ae1be98be5ced0c188859e2f9eef29 8910175fe9be3847f96a1cf3c877a3b54a64823d

Testing db6f15c7b4ae1be98be5ced0c188859e2f9eef29
Build done.
Installed. Restart running kernels to complete installation.

Testing 8910175fe9be3847f96a1cf3c877a3b54a64823d
Build done.
Installed. Restart running kernels to complete installation.

Single-input rule                       15.2 ± 0.6 %
Medium rule                             6.6 ± 0.8 %
Sequential rule                         6.6 ± 1.4 %
Large rule                              8.7 ± 0.5 %
Exponential-match-count rule            23.7 ± 0.8 %
CA emulator                             0.42 ± 0.21 %
```

Note, percentages correspond to runtime difference compared to the `oldBranch`, so, e.g., a positive `67 %` means there is a 3x improvement, whereas `-100 %` implies a 2x regression.

### Code review

First, if someone has assigned a `critical` pull request to you, please stop reading and review it as soon as possible (understand what the issue is, and verify the fix works). Many people might be blocked by it right now.

Otherwise, please review within one or two days or give an ETA to the pull request author if that is not possible.

The main objectives for the code review:
1. Verify the code works (i.e., make sure you can reproduce examples in the pull request message).
2. Read the code, understand it, and see if you can spot any potential weeds/unnecessary slowdowns/issues with it (including issues with code style as we currently only have a linter for the C++, but not for the Wolfram Language code).
3. Check the pull request has unit tests and changes documentation if appropriate.

We use [Reviewable](https://reviewable.io) for code review, which greatly simplifies the tracking of comments (Reviewable button should automatically appear on the bottom of pull requests). Please comment directly on the lines of code.

If you are reviewing a pull request from a fork, CI will not run automatically. You can (and need to) still run it manually, however, by pushing the changes to a new branch on GitHub. To do that, run the following where `123` is the pull request number:

```sh
git fetch origin pull/123/head:pr/123
git checkout pr/123
git push -u origin pr/123
```

The CI will automatically run and will be linked to the existing pull request.

After you receive a review and work on the changes, please reply to the reviewer on Reviewable so that they know when to look at your changes.

Last but not least, [be respectful](https://help.github.com/en/github/site-policy/github-community-guidelines), and give constructive criticism. Don't just say something is bad, say how to improve it.

### Merging

Generally speaking, the author of the pull request should be the one merging it. However, if you don't yet have collaborator access to the repository, you will have to ask someone else to do it.

Once you see the green "Squash and merge" button, all the necessary checks have passed, and you can merge your pull request! Congratulations! :tada: Push the green button, ***paste your pull request message to the commit message field***, and confirm. Your changes are now in and will be included in the next release.

## Code structure

The most important components of the package are the [Wolfram Language code](#wolfram-language-code), [C++ code](#libsetreplace), [tests](#tests), [documentation](#documentation), and [various scripts](#scripts).

### Wolfram Language code

The Wolfram Language code, which constitutes most of the package, lives in the [Kernel](/Kernel) directory. We use the [new-style package structure](https://mathematica.stackexchange.com/a/176489/46895).

Specifically, [init.m](/Kernel/init.m) is loaded first, followed by the rest of the files which are picked up automatically. Generally, each public Wolfram Language symbol would go to a separate file except for tiny ones (like constants), or huge functions that rely on other internal symbols (like [`WolframModel`](/Kernel/WolframModel.m)).

Each file should start with a ``Package["SetReplace`"]`` line, followed by lines of the form `PackageExport["PublicSymbolName"]` for publicly available symbols, and `PackageScope["PackageSymbolName"]` for private symbols that need to be used in other files. The symbols not included in either of these declarations are only available in that specific file.

Note these declarations are macros, not Wolfram Language code, so you have to put each one of them on a separate line, and you cannot use them with Wolfram Language code, like mapping them over a [`List`](https://reference.wolfram.com/language/ref/List.html).

Your public symbols should also include a `usage` message, which should be created with a [`usageString`](/Kernel/usageString.m) function. Each argument, number, and ellipsis should be [enclosed in backticks](https://github.com/maxitg/SetReplace/blob/6b9df76dc7fa3c08ac8803b90d625ce454f51f0c/Kernel/GeneralizedGridGraph.m#L7), which would automatically convert it to the correct style.

Further, public symbols must include [`SyntaxInformation`](https://reference.wolfram.com/language/ref/SyntaxInformation.html), see [an example](https://github.com/maxitg/SetReplace/blob/6b9df76dc7fa3c08ac8803b90d625ce454f51f0c/Kernel/WolframModel.m#L23) for `WolframModel`.

Functions must handle invalid inputs correctly. For example, if you try to evaluate

<img src="/Documentation/Images/ArgumentChecks.png" width="469">

you would get a helpful error message. If we did not do any checks here, we would instead have the code go haywire:

<img src="/Documentation/Images/NoArgumentChecks.png" width="582">

and the function would not even terminate, which is confusing and hostile to the user.

One way to implement such argument checking is to make special `valid*Q` functions, which would check each argument before running the function. This approach could work well for small functions. Still, it's not an ideal way to do it because sometimes the validity of the arguments can only be detected deep in the evaluation logic, and the validation function would be too complicated and lead to code duplication.

A better approach is to setup the function to catch exceptions, i.e.,

```wl
MakeUniverse[args___] := ModuleScope[
  result = Catch[makeUniverse[args]];
  result /; result =!= $Failed
]
```

and parse the inputs lazily, printing a message, and throwing an exception if something is wrong:

```wl
failUniverse[badUniverse_] := (
  Message[MakeUniverse::bad, badUniverse];
  Throw[$Failed]
)
```

This way, the error can occur arbitrarily deep in the function logic, and it would still be easy to immediately abort and return the function unevaluated.

---

The main dispatch function of *SetReplace* is the package-scope [`setSubstitutionSystem`](/Kernel/setSubstitutionSystem.m). It is essentially the generic evolution function. It is used by [`WolframModel`](/Kernel/WolframModel.m), [`SetReplace`](/Kernel/SetReplace.m), [`SetReplaceAll`](/Kernel/SetReplaceAll.m), etc.

[`setSubstitutionSystem`](/Kernel/setSubstitutionSystem.m) parses the options (except for [`WolframModel`](/Kernel/WolframModel.m)-specific ones), and uses one of the method functions, [`setSubstitutionSystem$cpp`](/Kernel/setSubstitutionSystem$cpp.m) or [`setSubstitutionSystem$wl`](/Kernel/setSubstitutionSystem$wl.m) to run the evolution.

[`setSubstitutionSystem$wl`](/Kernel/setSubstitutionSystem$wl.m) is the pure Wolfram Language implementation, which is more general (it supports arbitrary pattern rules and disconnected rules), but less efficient.

[`setSubstitutionSystem$cpp`](/Kernel/setSubstitutionSystem$cpp.m) on the other hand is the LibraryLink interface to [*libSetReplace*](#libsetreplace), which is the C++ implementation of Wolfram models.

If you'd like to implement a small utility useful throughout the package (but not accessible externally), put it in [utilities.m](/Kernel/utilities.m).

### libSetReplace

*libSetReplace* is the C++ library that implements the `"LowLevel"` method of [`WolframModel`](/Kernel/WolframModel.m). It lives in [`libSetReplace`](/libSetReplace) directory, and there is also the [Xcode project](/SetReplace.xcodeproj) for it. [`SetReplace.cpp`](/libSetReplace/SetReplace.cpp) and [`SetReplace.hpp`](/libSetReplace/SetReplace.hpp) implement the interface with Wolfram Language code.

The C++ implementation keeps an index of all possible rule matches and updates it after every replacement. The reindexing algorithm looks only at the local region of the graph close to the rewrite site. Thus time complexity is linear with the number of events and does not depend on the graph size as long as vertex degrees are small. The downside is that it has exponential complexity (both in time and memory) in the vertex degrees because an exponential number of matches might exist in that case. Currently, it also does not work for non-local rules (i.e., rule inputs that do not form a connected hypergraph) and rules that are not hypergraph rules (i.e., pattern rules that have non-trivial nesting or conditions).

Every time the `"LowLevel"` implementation of [`WolframModel`](/Kernel/WolframModel.m) is called, an instance of class [`Set`](/libSetReplace/Set.hpp) is created. [`Set`](/libSetReplace/Set.hpp) in turn uses the [`Matcher`](/libSetReplace/Match.hpp) class to perform the matching of set elements to rule inputs. [This class](/libSetReplace/Match.cpp) is the core of *SetReplace*.

#### Compile C++ library with CMake

The *libSetReplace* library can be used outside of Wolfram Language. It provides a CMake project for easy interaction with the C++ ecosystem.
To compile the core library using CMake:

```bash
mkdir build && cd build
cmake ..
cmake --build .
```

Options available for CMake:

- `SET_REPLACE_BUILD_TESTING`:
Enable cpp testing using googletest, which is downloaded at build time.

- `SET_REPLACE_WITH_MATHEMATICA`:
Generates the target `SetReplaceMathematica` that provides an interface for using *libSetReplace* in Wolfram Language.

- `SET_REPLACE_ENABLE_ALLWARNINGS`:
For developers and contributors. Useful for continuous integration. Add compile options to the targets enabling extra warnings and treating warnings as errors.

For example, to build *libSetReplace* with tests, replace the second line in the above with

```bash
cmake .. -DSET_REPLACE_BUILD_TESTING=ON
```

Then, after building, you can run the tests using the binaries in `libSetReplace/test/`.

#### Using SetReplace in third-party CMake projects

If a third-party project wants to use `SetReplace`, it is enough to write in their `CMakeLists.txt`:

```
add_library(foo ...)

find_package(SetReplace)
target_link_libraries(foo SetReplace::SetReplace)
#or target_link_libraries(foo SetReplace::SetReplaceMathematica)
```

and provide to their CMake project the CMake variable: `SetReplace_DIR` pointing to the file `SetReplaceConfig.cmake`.
This file can be found in the build directory of SetReplace, or in the `$CMAKE_INSTALL_PREFIX/lib/cmake/SetReplace` if
the project was installed.

### Tests

Tests live in the [Tests folder](/Tests). They are technically .wlt files, but they contain more structure.

Each file consists of a single [`Association`](https://reference.wolfram.com/language/ref/Association.html):

```wl
<|"FunctionName" -> <|"init" -> ..., "tests" -> {VerificationTest[...], ...}, "options" -> ...|>, ...|>
```

`"FunctionName"` is the name of a test group. It's what appears in the command line output of the test script to the left from `[ok]`. `"init"` is the code that runs before the tests. It usually contains definitions of test functions or constants commonly used in the tests. `"tests"` is code, which if evaluated after `"init"` results in the arbitrarily-nested structure of lists of [`VerificationTest`](https://reference.wolfram.com/language/ref/VerificationTest.html)s. Finally, `"options"` is currently only used to disable parallelization, which can be done by setting it to `{"Parallel" -> False}`.

Apart from [`VerificationTest`](https://reference.wolfram.com/language/ref/VerificationTest.html), there are other convenience testing functions defined in [testUtilities.m](/Kernel/testUtilities.m). For example, `testUnevaluated` can be used to test if the function returns unevaluated for given arguments. `testSymbolLeak` can check if internal symbols are not garbage-collected during the evaluation. `checkGraphics` and `graphicsQ` can check if the `Graphics` objects are valid (i.e., don't have pink background if shown in the Mathematica Front End). Since these are `PackageScope` functions, they need to be used as, e.g., ``SetReplace`PackageScope`testUnevaluated[VerificationTest, args]``. To avoid typing `PackageScope` every time, however, it is convenient to define them in `"init"` as, e.g.,

```wl
Attributes[Global`testUnevaluated] = {HoldAll};
Global`testUnevaluated[args___] := SetReplace`PackageScope`testUnevaluated[VerificationTest, args];
```

This way, the test itself can simply be defined as

```wl
testUnevaluated[
  MakeUniverse[42],
  {MakeUniverse::badUniverse}
]
```

Note that it's essential to test not only the functionality but also the behavior of the function in case it's called with invalid (or missing) arguments.

The tests should be deterministic so that they can be easily reproduced. If the test cases are randomly generated, this can be achieved by setting [`SeedRandom`](https://reference.wolfram.com/language/ref/SeedRandom.html).

If you want to implement performance tests, leave considerable leeway for the performance target, as the performance of CI servers may be different from what you might expect, and could fluctuate from run to run, which could result in randomly failing CI.

### Documentation

The *SetReplace* documentation is contained in three places: [README.md](/README.md), [CONTRIBUTING.md](CONTRIBUTING.md) (this file), and the code comments.

Some things to note are:
* Large [README](/README.md) sections should include navigation bars in the beginning.
* All references to functions should be links, either to [the Wolfram Language documentation](https://reference.wolfram.com/language/) or to the corresponding section in [README](/README.md).
* The comments in the Wolfram Language code are encouraged, and the C++ code is documented using [Doxygen](http://www.doxygen.nl).

### Scripts

The three main scripts of *SetReplace* are [build.wls](/build.wls), [install.wls](/install.wls) and [test.wls](/test.wls). The build script is the most complex of the three, and it uses additional definitions in [buildInit.wl](/scripts/buildInit.wl). In addition to building the C++ code and packing the paclet, it also auto-generates the paclet version number based on the number of commits to master from the checkpoint defined in [version.wl](/scripts/version.wl). Some of the code in the [scripts](/scripts) folder is only used for building *SetReplace* on the internal Wolfram Research systems and should not be modified by external developers as CI has no way of testing it.

## Code style

#### Wolfram Language

Unfortunately, there are no established style guidelines for Wolfram Language code. Here, the best rule is to try to be consistent as much as possible with the existing *SetReplace* code.

In addition to that, here are some more-or-less established rules:
* Keep line widths within 120 characters.
* Use at most a single empty line to separate code paragraphs (note, the Front End uses two by default, which should be manually fixed if you use the Front End for editing).
* Don't use section and cell definitions for comments, such as `(* ::Text:: *)`.
* Use spaces instead of tabs, and use 2 spaces for indentation.
* Close code block function brackets on the new line (for functions such as [`Module`](https://reference.wolfram.com/language/ref/Module.html), [`With`](https://reference.wolfram.com/language/ref/With.html) and [`If`](https://reference.wolfram.com/language/ref/If.html)):

  ```wl
  Module[{result = f[x]},
    result *= 2;
    result
  ]
  ```

  ```wl
  If[MatchQ[hypergraph, {__List}],
    Sort @ Union @ Catenate @ hypergraph,
    Throw @ $Failed
  ]
  ```

* However, close the brackets of ordinary functions on the same line as the last argument:

  ```wl
  veryLongFunctionCall[
    longArgument1, longArgument2, longArgument3]
  ```

* The function arguments should either all go on the same line, or should each be put on a separate line (except for special cases where a large quantity of short arguments is used):

  ```wl
  wolframModelPlot[
      edges_,
      edgeType_,
      styles_,
      hyperedgeRendering_,
      vertexCoordinates_,
      vertexLabels_,
      vertexSize_,
      arrowheadLength_,
      maxImageSize_,
      background_,
      graphicsOptions_] := Catch[
        ...]
  ```

* Avoid using [`Flatten`](https://reference.wolfram.com/language/ref/Flatten.html) and [`ReplaceAll`](https://reference.wolfram.com/language/ref/ReplaceAll.html) without explicit level arguments. That is because it is very easy to accidentally assume that the user's input is not a [`List`](https://reference.wolfram.com/language/ref/List.html) (e.g., a vertex name), even though it can be, in which case you would [`Flatten`](https://reference.wolfram.com/language/ref/Flatten.html) too much, and cause a weed. It is preferred to use [`Catenate`](https://reference.wolfram.com/language/ref/Catenate.html) and [`Replace`](https://reference.wolfram.com/language/ref/Replace.html) instead of these functions.
* Similar issue could happen with [`Thread`](https://reference.wolfram.com/language/ref/Thread.html), especially when used to thread a single element over multiple. For example, it is easy to assume naively that `Thread[x -> {1, 2, 3}]` would always yield `{x -> 1, x -> 2, x -> 3}`. Except, sometimes it might be called as `With[{x = {4, 5, 6}}, Thread[x -> {1, 2, 3}]]`.
* Use uppercase camel for public symbols, lowercase camel for internal (including PackageScope) symbols:

  ```wl
  PackageExport["WolframModelEvolutionObject"]

  PackageScope["propertyEvaluate"]
  ```

* Start global constants with `$`, whether internal or public, and tags (such as used in [`Throw`](https://reference.wolfram.com/language/ref/Throw.html) or [`Sow`](https://reference.wolfram.com/language/ref/Sow.html), or as generic enum labels) with `$$`. Global pure functions (defined as [`OwnValues`](https://reference.wolfram.com/language/ref/OwnValues.html)) should still be treated as ordinary (e.g., [`DownValues`](https://reference.wolfram.com/language/ref/DownValues.html)) functions and not start with `$`, unless they are public, in which case they should start with `$` and end with the word `Function`.
* Use the macros `ModuleScope` and `Scope` (defined in ``"GeneralUtilities`"``) instead of `Module` and `Block` (respectively) when defining functions of the form `f[x__] := (Module|Block)[...]`. The main benefit of using them is that there is no need to specify a list of local variables (i.e. `{localVar1, localVar2, ...}`) at the begining, as a list of local variables will be automatically generated by looking for expressions of the form `Set` (`=`) or `SetDelayed` (`:=`) anywhere in the body of the function (See `?Scope` and [#460](https://github.com/maxitg/SetReplace/pull/460) for more information). For example:

  ```wl
  example[hypergraph1_, hypergraph2_] := ModuleScope[
    {vertexList1, vertexList2} = getVertexList /@ {hypergraph1, hypergraph2};
    If[Length @ hypergraph1 >= Length @ hypergraph2,
      size = Length @ hypergraph1,
      size = Length @ hypergraph2
    ];
  ]
  ```
  is expanded to:

  ```wl
  example[hypergraph1_, hypergraph2_] := Module[{vertexList1, vertexList2, size},
    {vertexList1, vertexList2} = getVertexList /@ {hypergraph1, hypergraph2};
    If[Length @ hypergraph1 >= Length @ hypergraph2,
      size = Length @ hypergraph1,
      size = Length @ hypergraph2
    ];
  ]
  ```

#### C++
The code should follow [Google C++ Style](https://google.github.io/styleguide/cppguide.html) guidelines, save for the
following exceptions:
* Maximum line length is 120 characters.
* Function and variable names, including const and constexpr variables, use lower camel case.
* Namespace and class names use upper camel case.
* C++ exceptions may be thrown.
* White space in pointer and reference declarations goes after the `*` or `&` character. For example:
    * `int* foo;`
    * `const std::string& string;`
* If splitting function arguments into multiple lines, each argument should go on a separate line.
* License, authors, and file descriptions should not be put at the top of files.
* Doxygen format is used for documentation.
* We use `.cpp` and `.hpp` extensions for source files.

We use [`clang-format`](https://clang.llvm.org/docs/ClangFormat.html) for formatting and
[`cpplint`](https://raw.githubusercontent.com/google/styleguide/gh-pages/cpplint/cpplint.py) for linting.

To run these automatically, call `./lint.sh`. This will print a formatting diff and error messages from `cpplint`.
If there are no errors found, it will exit with no output.
To edit the code in place with the fixed formatting use `./lint.sh -i`.

If `cpplint` flags a portion of your code, please make sure it is adhering to the proper code style. If it is a false
positive or if there is no reasonable way to avoid the flag, you may put `// NOLINT` at the end of the line if there is
space, or `// NOLINTNEXTLINE` on a new line above if there is no space. For any usages of `// NOLINT` or
`// NOLINTNEXTLINE`, please describe the reason for its inclusion both in a code comment and in your pull request's
comments section.

If you want to disable formatting, use `// clang-format off` and `// clang-format on` around the manually formatted
code.

#### Markdown
We are using GitHub-flavored Markdown for documentation and research notes.

Images (e.g., of output cells) should be made by selecting the relevant cells in the Front End, copying them as bitmaps, and saving them as .png files to [Documentation/Images](/Documentation/Images) (in the documentation) or to the Images directory of the corresponding research note. They should then be inserted using the code similar to this:

  ```html
  <img src="/Documentation/Images/image.png" width="xxx">
  ```

  where the `width` should be computed as

  ```wl
  Round[0.6 First @ Import["$RepoRoot/Documentation/Images/image.png", "ImageSize"]]
  ```

# Research

We have recently started publishing research notes directly in *SetReplace*. These research notes should go to the [Research](/Research) directory.

The idea here is to have a mini-"journal", where the peer review is implemented in the same way as code review, the documents are organized as a wiki (by subject rather than by date), and can be updated any time.

We expect the same high level of quality here as in the rest of *SetReplace*. In particular, we should be reasonably confident that everything written in the research notes is correct. This means:
* If you are discussing a hypothesis or speculation that is not necessarily correct, it should be explicitly mentioned in the text.
* If you rely on results of a computation, you can only use stable code to run that computation. This includes *SetReplace* and build-in Wolfram Language functions. However, it ***does not*** include Wolfram Function Repository functions. If you need to rely on such functions' output, you will need to add similar functionality to *SetReplace* first.
* However, you can use Wolfram Function Repository functions for demonstration purposes in cases where their output can be easily verified by a reviewer.
* You are equivally welcome to modify existing research notes as well as create new ones. You don't have to be the original author of the note to modify it (although it is a good idea to request a review from the original author).

Research notes should follow the same [development process](#development-process) as the rest of *SetReplace* except for tests. In particular, pull requests should still be kept under 500 lines and follow the [Markdown formatting rules](#markdown).

That's all for our guidelines, now let's go figure out the fundamental theory of physics! :rocket:
