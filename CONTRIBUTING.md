First, thanks for contributing! :balloon: :gear: :thumbsup:

These are the guidelines designed to make the development smooth, efficient and fun for all of us. But remember, they are created by us, not set in stone, and anybody is welcome to propose changes. Just open a pull request.

There are fundamentally two kinds of things you can contribute: issues (reports and ideas) and code.

# Issues

## Weed reports (something is not working)

First off, while it's common to call problems with the code "bugs", we call them *weeds* here instead (kudos to [@aokellermann](https://github.com/aokellermann)). That's because using the word "bug" in a negative context implicitly sends a message that *bugs* (aka insects) are someone bad and should be squashed. We don't agree with that sentiment, as *bugs* :ant: :beetle: :spider: are living creatures who deserve moral consideration. Hence, let's live "bugs" alone, and go *weed whacking*.

Also note, this repository is all about software. If you have found a issue with our physics model, or a mistake in one of our papers, please contact the author directly, or see our [contact page](???). Also, this repository is only about the *SetReplace* paclet. If you have found a week in a function repository function, use the form on that function's documentation page to contact the author directly.

To report a weed, follow these steps:
1. Go the the [Issues page](https://github.com/maxitg/SetReplace/issues), and use the search to check if the weed you have encountered is in the list already. If it is, and it was not getting much attention recently, the best you can do is to comment that you care abut it being fixed, and leaving the example you have encountered that's not working (if it's different).
2. If the weed is not in the list, click "New issue", and then "Get started" next to the "Weed report".
3. Fill in all the fields including:
  * The line of Wolfram Language code that results in unexpected behavior (or a screenshot if the weed is in the UI).
  * The actual output you are getting.
  * The output you expect to see.
  * Include the output of `SystemInformation["Small"]` and `$SetReplaceGitSHA`.
4. If you have a Mathematica notebook with more details, you can attach it to the issue, but you will have to compress it into a `ZIP` first.
5. Click submit new issue.
6. Your issue is now in the list, and a developer will try to look at it when they have a chance. But if it does not get any attention, the best thing you can do is to [fix it yourself](#code).

## Feature suggestions

If you have an idea to improve an existing function, add a property to `WolframModel`, or for a new function that does not currently exist, you can suggest it by creating a feature request. Someone might implement it if they like the idea, but there are no guarantees. Also note, this repository is all about software, for research ideas see our [contact page](???).

The process is similar to weed reports, except use "Feature request" option for the new issue instead of "Weed report", and don't include any version information.

# Code

If you would like to contribute code, thanks again! :balloon: :balloon: :balloon: :gear: :thumbsup:

In the sections below, we describe our development process, the code structure, and our code style rules. However, if you are unsure about something, don't let these rules deter you from opening pull requests! If something is missing, or if there are issues with code style, someone will just point them out during code review.

## Development process

Each change to the code must fundamentally pass through 5 steps, more or less in that order: writing code, opening a pull request, passing automated tests, passing code review, and merging the PR.

### Writing code

In addition to the code itself, each pull request should include unit tests and documentation.

To help you get started, see how the code is [organized](#code-structure) and our notes on [code style](#code-style). Also, we are keeping dependencies to a minimum to make the paclet as easy to compile and run as possible. So, avoid adding dependencies if at all possible. That includes Wolfram Function Repository functions. Even though they don't require installation, most of them are not stable enough for use in *SetReplace*. In addition, using them will result in unexpected behavior (as they can be updated independently of *SetReplace*, and there is no way to enforce a specific version), generate unexpected messages (i.e., for updates) and use Internet connection causing unexpected slowdowns. If you still think adding a dependency is worth it, please open a feature request first to discuss it.

The unit tests are particularly important if you are implementing a weed fix, as we need to make sure the weed you are fixing is not going to return in the future. And if you are implementing a new function, unit tests should not only cover the functionality, but also the behavior in case the function is called with invalid arguments. Each function should have at least some unit tests, otherwise one of the tests in [meta.wlt](Tests/meta.wlt) will fail.

You should also modify documentation in the [README](README.md) if you are implementing new functionality, or causing any outputs already in the [README](README.md) to change.

### Opening a pull request

Each pull request message should include detailed information on what was changed, optional comments for the reviewer, and **examples**, including screenshots if the output is a graphics. If your pull request closes an existing issue (as it generally should, as it's best to discuss your changes before implementing them), reference that issue in your pull request message. For an example of a good pull request message, see [#268](https://github.com/maxitg/SetReplace/pull/268).

Next, assign one of the type [labels](https://github.com/maxitg/SetReplace/labels) to your pull request:
* `feature`: new functionality, or change in existing functionality.
* `optimization`: does not change functionality, but makes code faster.
* `refactor`: does not change functionality, but makes the code more readable.
* `weed`: fixes a weed.

In addition, one or both of the following may be used:
* `critical`: fixes something that severely breaks the package (usually used for weeds).
* `breaking`: introduces API changes that would break existing code, better to avoid if possible.

Next, assign a reviewer to your pull request. Ideally, it should be someone who have recently edited the same files you are changing. If in doubt, assign to [@maxitg](https://github.com/maxitg).

It is important to keep your pull requests as small as possible (definitely under 1000 lines). This not only makes them easier to review and generally improves review quality, but also makes it more likely your changes will find their way into master, as it's always possible you will get distructed and won't be able to finish a one giant pull request. It also helps with keeping your pull requests up-to-date with master, which is important because changes in master might introduce conflicts or break your code.

### Automated tests

TODO: add content

### Code review

TODO: add content

### Merging

TODO: add content

## Code structure

TODO: add content, start by explaining how WL packages work.

## Code style
