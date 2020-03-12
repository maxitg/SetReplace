# Set Substitution System

## Basic Example

**SetReplace** is a [Wolfram Language](https://www.wolfram.com/language/) package to manipulate set substitution systems. To understand what a set substitution system does consider an unordered set of elements:
```
{1, 2, 5, 3, 6}
```
We can set up an operation on this set which would take any of the two elements and replace them with their sum:
```
{a_, b_} :> {a + b}
```
In **SetReplace**, this can be expressed as (the new element is put at the end)
```
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}]
Out[] = {5, 3, 6, 3}
```
Note that this is similar to `SubsetReplace` function of Wolfram Language (which did not exist prior to version 12.1, and which by default replaces all non-overlapping subsets at once)
```
In[] := SubsetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> Sequence[a + b]]
Out[] = {3, 8, 6}
```

## Relations between Set Elements

A more interesting case (and the only case we have studied with any reasonable detail) is the case of set elements that are related to each other. Specifically, the elements can be expressed as ordered lists of atoms (or vertices), and the set essentially becomes an ordered hypergraph.

As a simple example consider a set
```
{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}
```
which we can render as a collection of ordered hyperedges:
```
In[] := HypergraphPlot[{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}},
 VertexLabels -> Automatic]
```
![{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}](READMEImages/basicHypergraph.png)

We can then have a rule which would pick a subset of expressions related in a particular way (much like a join query) and replace them with something else. Note the [`Module`](https://reference.wolfram.com/language/ref/Module.html) on the right-hand side creates a new variable (vertex) which causes the hypergraph to grow.
```
{{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```
After a single replacement we get this (note the new vertex)
```
In[] := HypergraphPlot[
 SetReplace[{{1, 2, 3}, {2, 4, 5}, {4, 6,
    7}}, {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
   Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]],
 VertexLabels -> Automatic]
```
![{{4, 6, 7}, {5, v1938, 1}, {v1938, 4, 2}, {4, 5, 3}}](READMEImages/basicRuleOneStep.png)

After 10 steps, we get a more complicated structure
```
In[] := HypergraphPlot[
 SetReplace[{{1, 2, 3}, {2, 4, 5}, {4, 6,
    7}}, {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
   Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}], 10],
 VertexLabels -> Automatic]
```
![{{7, 2, v1960}, {7, v1965, 6}, {v1965, v1962, 4}, {v1962, 7, v1959}, {3, v1966, v1963}, {v1966, 1, v1959}, {1, 3, v1961}, {1, v1967, v1959}, {v1967, v1963, 5}, {v1963, 1, 4}, {6, v1968, 2}, {v1968, 7, v1964}, {7, 6, v1962}}](READMEImages/basicRuleTenSteps.png)

And after 100 steps, it gets even more complicated
```
In[] := HypergraphPlot[
 SetReplace[{{1, 2, 3}, {2, 4, 5}, {4, 6,
    7}}, {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
   Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}], 100]]
```
![basicRuleHundredSteps](READMEImages/basicRuleHundredSteps.png)

Exploring the models of this more complicated variety is what this package is mostly designed for.

# Getting Started

## Prerequisites

To start using `SetReplace` you only need two things.

* [Wolfram Language 12.1+](https://www.wolfram.com/language/) including [WolframScript](https://www.wolfram.com/wolframscript/). A free (although not open-source) version is available as [Wolfram Engine](https://www.wolfram.com/engine/).
* A C++ compiler to build the low-level part of the package. Instructions on how to setup a compiler to use in WolframScript in various platforms are [available](https://reference.wolfram.com/language/CCompilerDriver/tutorial/SpecificCompilers.html#509267359).

## Build Instructions

To build,
1. `cd` to the root directory of the repository.
2. Run `./build.wls` to create the paclet file.
If you see an error message about c++17, make sure the C++ compiler you are using is up-to-date. If your default system compiler does not support c++17, you can choose a different one with environmental variables. The following, for instance, typically works on a Mac:
```
COMPILER=CCompilerDriver\`ClangCompiler\`ClangCompiler COMPILER_INSTALLATION=/usr/bin ./build.wls
```
Here `ClangCompiler` can be replaced with one of `"Compiler" /. CCompilers[Full]` (run ``<< CCompilerDriver` `` to use `CCompilers`), and `COMPILER_INSTALLATION` is a directory in which the compiler binary can be found.

3. Run `./install.wls` to install the paclet into your Wolfram system.
4. Evaluate `PacletDataRebuild[]` in all running Wolfram kernels.
5. Evaluate ``<< SetReplace` `` every time prior to using package functions.

A less frequently updated version is available through the Wolfram's public paclet server and can be installed by running `PacletInstall["SetReplace"]`.

# Symbols and Functions

## SetReplace, SetReplaceList, SetReplaceAll, SetReplaceFixedPoint and SetReplaceFixedPointList

`SetReplace` (and related `SetReplaceList`, `SetReplaceAll`, `SetReplaceFixedPoint` and `SetReplaceFixedPointList`) are the functions the package is named after. They are quite simple, don't have a lot of options, and simply perform replacement operations either one-at-a-time (as in the case of `SetReplace`), to all non-overlapping subsets (`SetReplaceAll`), or until no more matches can be made (`SetReplaceFixedPoint`). A suffix `*List` implies the function will return a set after each replacement instead of just the final result.

These functions are good for their simplicity, but we don't use them much anymore as a more advanced `WolframModel` incorporates all of these features plus other utilities helpful for the exploration of our models.

As was mentioned previously, `SetReplace` performs a single iteration if called with two arguments:
```
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}]
Out[] = {5, 3, 6, 3}
```

It can be supplied a third argument specifying the number of replacements (the same can be achieved using `Nest`):
```
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}, 2]
Out[] = {6, 3, 8}
```

If the number of replacements is set to `Infinity` calling `SetReplace` is equivalent to `SetReplaceFixedPoint`:
```
In[] := SetReplace[{1, 2, 5, 3, 6}, {a_, b_} :> {a + b}, \[Infinity]]
Out[] = {17}
```

It is possible to use multiple rules as well (here the subsets `{1, 5}` and then `{2, 6}` are replaced):
```
In[] := SetReplace[{1, 2, 5, 3,
  6}, {{a_?EvenQ, b_?EvenQ} :> {a + b}, {a_?OddQ,
    b_?OddQ} :> {a + b}}, 2]
Out[] = {3, 6, 8}
```

`SetReplaceList` can be used to see the set after each replacement (here a list is omitted on the right-hand side of the rule, which can be done if the subset only contains a single element):
```
In[] := SetReplaceList[{1, 2, 5, 3, 6}, {a_, b_} :> a + b, \[Infinity]]
Out[] = {{1, 2, 5, 3, 6}, {5, 3, 6, 3}, {6, 3, 8}, {8, 9}, {17}}
```

`SetReplaceAll` replaces all non-overlapping subsets:
```
In[] := SetReplaceAll[{1, 2, 5, 3, 6}, {a_, b_} :> a + b]
Out[] = {6, 3, 8}
```

`SetReplaceFixedPoint` and `SetReplaceFixedPointList` perform replacements for as long as possible as previously mentioned:
```
In[] := SetReplaceFixedPoint[{1, 2, 5, 3, 6}, {a_, b_} :> a + b]
Out[] = {17}
```
```
In[] := SetReplaceFixedPointList[{1, 2, 5, 3, 6}, {a_, b_} :> a + b]
Out[] = {{1, 2, 5, 3, 6}, {5, 3, 6, 3}, {6, 3, 8}, {8, 9}, {17}}

```

All of these functions have `Method`, `TimeConstraint` and `"EventOrderingFunction"` options. `TimeConstraint` is self-evident, the other two work the same way as they do in `WolframModel` and will be described further in the `WolframModel` part of this README.

## ToPatternRules

`ToPatternRules` is a convenience function used to quickly enter rules such as the one mentioned previously
```
{{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```

This is the type of rule we study the most, and it satisfies the following set of conditions:
* Both input and output subsets consist of (ordered) lists of atoms (aka vertices).
* The input (left-hand side) only contains patterns, it never refers to explicit vertex names.
* The name of the vertex is only used to identify it, it does not contain any additional information. As such, there are no conditions specified on the left-hand side of the rule (neither on the entire subset, nor on individual vertices), except for the implicit condition of some vertices appearing multiple times in different lists.
* The output may contain new vertices (i.e., the ones that don't appear on the left-hand side), in which case they are created with a `Module`.

`ToPatternRules` provides a simpler way to specify such rules by automatically assuming that the level-2 expressions on the left-hand side are patterns, and that vertices used on the right which don't appear on the left are new and should be created with a `Module`. For example, the rule above can simply be written as
```
In[] := ToPatternRules[{{v1, v2, v3}, {v2, v4, v5}} -> {{v5, v6, v1}, {v6, v4,
     v2}, {v4, v5, v3}}]
Out[] = {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```
or even simpler as
```
In[] := ToPatternRules[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5,
     3}}]
Out[] = {{v1_, v2_, v3_}, {v2_, v4_, v5_}} :>
 Module[{v6}, {{v5, v6, v1}, {v6, v4, v2}, {v4, v5, v3}}]
```

This last form of the rule is the one that we use most often, and is also the one that is accepted by `WolframModel` by default (more on that in `WolframModel` section).

`ToPatternRules` is listable in a trivial way:
```
In[] := ToPatternRules[{{{1, 2}} -> {{1, 2}, {2, 3}}, {{1, 2}} -> {{1, 3}, {3,
      2}}}]
Out[] = {{{v1_, v2_}} :> Module[{v3}, {{v1, v2}, {v2, v3}}], {{v1_, v2_}} :>
  Module[{v3}, {{v1, v3}, {v3, v2}}]}
```

## WolframModel and WolframModelEvolutionObject

`WolframModel` is the main function of the package, and provides tools for the generation and analysis of set substitution systems. It can compute many different properties of the evolution, and has many different options, which are described in the corresponding subsections.

The most basic way to call it however is this:
```
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5,
    3}}, {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 10]
```
![WolframModelBasicEvolution10](READMEImages/WolframModelBasicEvolution10.png)

Note this call is different from using the `SetReplace` function in a variety of ways:
* The order of arguments is switched, the rule goes first.
* The rule is specified in the "anonymous" form (i.e., `ToPatternRules` is done implicitly).
* The number of steps here is defined the same way as in `SetReplaceAll`, which is also known as the number of generations. Here each edge can have at most 10 generations of predecessors.
* The output is not a final state, but instead an object which contains the entire evolution (similar to `SetReplaceList`) but with additional information about which rules are being used at each replacement. From the information field on that object one can see that the evolution was done for 10 generations (i.e., a fixed point has not been reached early), and 109 replacements (aka events) were made in total. More properties can be computed from an evolution object, more on that later.

To see the information an evolution object contains, let's make one with a smaller number of generations:
```
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5,
    3}}, {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 3]
```
![WolframModelBasicEvolution3](READMEImages/WolframModelBasicEvolution3.png)

One can easily see its internal structure in the `InputForm`:
![WolframModelBasicEvolution3 // InputForm](READMEImages/WolframModelBasicEvolution3InputForm.png)
```
Out[] = WolframModelEvolutionObject[<|"CreatorEvents" -> {0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4,
   4, 4, 5, 5, 5}, "DestroyerEvents" -> {1, 1, 2, 3, 2, 3, 4, 4, Infinity, 5, 5,
    Infinity, Infinity, Infinity, Infinity, Infinity, Infinity, Infinity},
  "Generations" -> {0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3},
  "AtomLists" -> {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}, {5, 8, 1}, {8, 4, 2}, {4, 5, 3},
    {7, 9, 8}, {9, 6, 4}, {6, 7, 2}, {1, 10, 4}, {10, 8, 5}, {8, 1, 3}, {4, 11, 7},
    {11, 6, 9}, {6, 4, 8}, {5, 12, 1}, {12, 8, 10}, {8, 5, 4}},
  "Rules" -> {{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}},
  "MaxCompleteGeneration" -> 3, "TerminationReason" -> "MaxGenerationsLocal",
  "EventRuleIDs" -> {1, 1, 1, 1, 1}|>]
```

The most important part of that association is `"AtomLists"` which includes all set elements (aka expressions or edges) ever created throughout history. Note, this does not correspond to any particular step, rather all steps are combined. They are not just catenated states as well, as if a particular expression was never used as an input for any replacement in a particular step, it would not be duplicated in that list. To see how that works, compare it to `"StatesList"` and observe that a catenated `"StatesList"` would contain more expressions than `"AtomLists"` does.
![WolframModelBasicEvolution3["StatesList"]](READMEImages/WolframModelBasicEvolution3StatesList.png)
```
Out[] = {{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, {{4, 6, 7}, {5, 8, 1}, {8, 4,
   2}, {4, 5, 3}}, {{7, 9, 8}, {9, 6, 4}, {6, 7, 2}, {1, 10, 4}, {10,
   8, 5}, {8, 1, 3}}, {{6, 7, 2}, {8, 1, 3}, {4, 11, 7}, {11, 6,
   9}, {6, 4, 8}, {5, 12, 1}, {12, 8, 10}, {8, 5, 4}}}
```

Each edge in `"AtomLists"` has properties which are storied in other lists of the evolution object:
* `"CreatorEvents"` shows which event (aka replacement) (referenced by its index) has this edge as one of its outputs.
* `"DestroyerEvents"` shows which event has this edge as an input. Note that even though multiple matches could be possible that involve a particular edge, in the current implementation only one of these matches will be used (see `"EventOrderingFunction"` option on how to control which match to use).
* `"Generations"` shows how many layers of predecessors a given edge has.
* `"Rules"` is an exact copy of the `WolframModel` input.
* `"MaxCompleteGenerations"` shows the largest generation in which no matches are possible that only involve expressions of this or earlier generations. In this particular case, it is the same as the largest generation of any edge, but it might be different if a more elaborate [step specification](#step-limiters) is used.
* `"TerminationReason"` shows the reason evaluation was stopped. See the [`"TerminationReason"`](#terminationreason) property for more details.
* Finally, `"EventRuleIDs"` shows which rule was used for each event. It's rather boring in this particular case as only one rule is used in this example.

A specific property can be requested from an evolution object in a similar way as a property for an `Entity`. The list of available properties can be found [below](#properties).
![WolframModelBasicEvolution10["EventsCount"]](READMEImages/WolframModelBasicEvolution10EventsCount.png)
```
Out[] = 109
```

List of all available properties can be obtained with a `"Properties"` property:
![WolframModelBasicEvolution10["Properties"]](READMEImages/WolframModelBasicEvolution10Properties.png)
```
Out[] = {"EvolutionObject", "FinalState", "FinalStatePlot", "StatesList", \
"StatesPlotsList", "EventsStatesPlotsList", \
"AllEventsStatesEdgeIndicesList", "AllEventsStatesList", \
"Generation", "StateEdgeIndicesAfterEvent", "StateAfterEvent", \
"Rules", "TotalGenerationsCount", "PartialGenerationsCount", \
"GenerationsCount", "GenerationComplete", "AllEventsCount", \
"GenerationEventsCountList", "GenerationEventsList", \
"FinalDistinctElementsCount", "AllEventsDistinctElementsCount", \
"VertexCountList", "EdgeCountList", "FinalEdgeCount", \
"AllEventsEdgesCount", "AllEventsGenerationsList", "CausalGraph", \
"LayeredCausalGraph", "TerminationReason", "AllEventsRuleIndices", \
"AllEventsList", "EventsStatesList", "Properties", \
"EdgeCreatorEventIndices", "EdgeDestroyerEventIndices", \
"EdgeGenerationsList", "AllEventsEdgesList", \
"CompleteGenerationsCount"}
```

Some properties take additional arguments, which can be supplied after the property name:
![WolframModelBasicEvolution10["StateAfterEvent", 7]](READMEImages/WolframModelBasicEvolution10StateAfterEvent7.png)
```
Out[] = {{8, 1, 3}, {5, 12, 1}, {12, 8, 10}, {8, 5, 4}, {2, 13, 11}, {13, 7,
  6}, {7, 2, 9}, {7, 14, 6}, {14, 11, 4}, {11, 7, 8}}
```

A particular generation can be extracted simply by number (including, i.e., -1 for the final state):
![WolframModelBasicEvolution10[3]](READMEImages/WolframModelBasicEvolution10Generation3.png)
```
Out[] = {{6, 7, 2}, {8, 1, 3}, {4, 11, 7}, {11, 6, 9}, {6, 4, 8}, {5, 12,
  1}, {12, 8, 10}, {8, 5, 4}}
```

If a property does not take any arguments, it can be specified directly in `WolframModel` as a shorthand:
```
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5,
    3}}, {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 10, "EdgeCountList"]
Out[] = {3, 4, 6, 8, 12, 18, 24, 36, 54, 76, 112}
```

All properties available to use directly in `WolframModel` can be looked up in `$WolframModelProperties` (there are more properties here compared to the list above because some properties are available under multiple names, and only the canonical name is listed above).
```
In[] := $WolframModelProperties
Out[] = {"AllEventsCount", "AllEventsDistinctElementsCount", \
"AllEventsEdgesCount", "AllEventsEdgesList", \
"AllEventsGenerationsList", "AllEventsList", "AllEventsRuleIndices", \
"AllEventsStatesEdgeIndicesList", "AllEventsStatesList", \
"AllExpressions", "AtomsCountFinal", "AtomsCountTotal", \
"CausalGraph", "CompleteGenerationsCount", "CreatorEvents", \
"DestroyerEvents", "EdgeCountList", "EdgeCreatorEventIndices", \
"EdgeDestroyerEventIndices", "EdgeGenerationsList", \
"EventGenerations", "EventGenerationsList", "EventsCount", \
"EventsList", "EventsStatesList", "EventsStatesPlotsList", \
"EvolutionObject", "ExpressionGenerations", "ExpressionsCountFinal", \
"ExpressionsCountTotal", "FinalDistinctElementsCount", \
"FinalEdgeCount", "FinalState", "FinalStatePlot", \
"GenerationComplete", "GenerationEventsCountList", \
"GenerationEventsList", "GenerationsCount", "LayeredCausalGraph", \
"MaxCompleteGeneration", "PartialGenerationsCount", "StatesList", \
"StatesPlotsList", "TerminationReason", "TotalGenerationsCount", \
"UpdatedStatesList", "VertexCountList"}
```

Multiple properties can also be specified in a list (only in `WolframModel`, not in `WolframModelEvolutionObject`):
```
In[] = WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5,
    3}}, {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 10, {"EdgeCountList",
  "VertexCountList"}]
Out[] = {{3, 4, 6, 8, 12, 18, 24, 36, 54, 76, 112}, {7, 8, 10, 12, 16, 22, 28,
   40, 58, 80, 116}}
```

### Rule Specification

#### Multiple Rules

Multiple rules can simply be specified as a list of rules.
```
In[] := WolframModel[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2, 3}}, {{1,
     2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, {{1, 1, 1}}, 4]
```
![WolframModelMultipleRulesObject](READMEImages/WolframModelMultipleRulesObject.png)

To see which rules were used for each replacement:
![WolframModelMultipleRulesObject["AllEventsRuleIndices"]](READMEImages/WolframModelMultipleRulesObjectAllEventsRuleIndices.png)
```
Out[] = {1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2}
```

#### Pattern Rules

Pattern rules (i.e., the kind of rules used in the `SetReplace` function) can be specified as well. As an example, previously described call to `SetReplaceList` can be reproduced as
```
In[] := WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {1, 2, 5, 3,
  6}, \[Infinity], "AllEventsStatesList"]
Out[] = {{1, 2, 5, 3, 6}, {5, 3, 6, 3}, {6, 3, 8}, {8, 9}, {17}}
```

### Automatic Initial State

An initial state consistint of an appropriate number of (hyper) self-loops can be automatically produced for anonymous (non-pattern) rules (here we evolve the system for 0 steps and ask the evolution object for the 0-th generation aka the initial state).
```
In[] := WolframModel[{{1, 2}, {1, 2}} -> {{3, 2}, {3, 2}, {2, 1}, {1, 3}},
  Automatic, 0][0]
Out[] = {{1, 1}, {1, 1}}
```

That even works for multiple rules in which case the loops are chosen in such a way that any of the rules can match
```
In[] := WolframModel[{{{1, 2}, {1, 2}} -> {{3, 2}, {3, 2}, {2, 1, 3}, {2,
      3}}, {{2, 1, 3}, {2, 3}} -> {{2, 1}, {1, 3}}}, Automatic, 0][0]
Out[] = {{1, 1}, {1, 1}, {1, 1, 1}}
```

Note that because different patterns can be matched to the same symbol, this initial state is guaranteed to match the rules at least once (no guarantees after that).

### Step Limiters

The standard numeric argument to `WolframModel` specifies the number of generations.
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} -> {{7, 1, 8}, {9,
     3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13, 7}, {8, 10}, {10,
     8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}}, {{1, 2, 3}, {4, 5,
   6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6,
   3}}, 6, "FinalStatePlot"]
```
![WolframModelFixedGenerationsFinalStatePlot](READMEImages/WolframModelFixedGenerationsFinalStatePlot.png)

Alternatively, an `Association` can be used to specify multiple limiting conditions
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} -> {{7, 1, 8}, {9,
     3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13, 7}, {8, 10}, {10,
     8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}}, {{1, 2, 3}, {4, 5,
   6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6, 3}}, <|
  "MaxVertices" -> 300, "MaxEvents" -> 200|>, "FinalStatePlot"]
```
![WolframModelMaxVerticesFinalStatePlot](READMEImages/WolframModelMaxVerticesFinalStatePlot.png)

Note that the final state in this case is "less symmetric" because its last generation is incomplete (more on that [later](#hypergraphautomorphismgroup)). Such incomplete generations can be automatically trimmed by setting [`"IncludePartialGenerations" -> False`](#includepartialgenerations).

One can also see the presence of an incomplete generation by looking at the evolution object (note `5...6` which means 5 generations are complete, and 1 is not). Expanding the object's information, one can also see that in this particular case the evolution was terminated because `"MaxVertices"` (not `"MaxEvents"`) condition was reached:
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} -> {{7, 1, 8}, {9,
     3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13, 7}, {8, 10}, {10,
     8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}}, {{1, 2, 3}, {4, 5,
   6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6, 3}}, <|
  "MaxVertices" -> 300, "MaxEvents" -> 200|>]
```
![WolframModelMaxVerticesEvolution](READMEImages/WolframModelMaxVerticesEvolution.png)

All possible keys in that association are:
* `"MaxEvents"`: limit the number of individual replacements (in the `SetReplace` function meaning).
* `"MaxGenerations"`: limit the number of generations (steps in `SetReplaceAll` meaning), same as specifying steps directly as a number in `WolframModel`.
* `"MaxVertices"`: limit the number of vertices in the *final* state only (the total count throughout history might be larger). This will stop evolution if the next event if applied will put the state over the limit. Note once such an event is encountered it will stop evolving immediately even if other matches exist that would not put the vertex count over the limit.
* `"MaxVertexDegree"`: limit the number of final state edges any particular vertex is involved in. Works in a similar way to `"MaxVertices"`.
* `"MaxEdges"`: limit the number of edges (expressions) in the final state. Similar to `"MaxVertices"`.

Any combination of these will be used, in which case the earliest triggered will stop the evolution.

Note also that `"MaxGenerations"` works differently from the other limiters, as the matching algorithm would not even attempt to match edges with generations over the limit. This means that unlike, i.e., `"MaxVertices"` which would terminate the evolution immediately once the limit-violating event is attempted, `"MaxGenerations"`-limited evolution will keep "filling in" events for as long as possible until no further matches within allowed generations can be made.

### Properties

#### FinalState (aka -1), StatesList, Generation, AllEventsStatesList, StateAfterEvent (aka SetAfterEvent)

These are the properties used to extract states at a particular moment in the evolution. They always return lists, but in the examples below we plot them for clarity.

`FinalState` yields the state obtained after all replacements of the evolution have been made:
```
In[] := WolframModelPlot@
 WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
     10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
     9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6,
  "FinalState"]
```
![WolframModelPropertiesFinalState](READMEImages/WolframModelPropertiesFinalState.png)

`"StateList"` yields the list of states at each generation:
```
In[] := WolframModelPlot /@
 WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
     10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
     9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6,
  "StatesList"]
```
![WolframModelPropertiesStatesList](READMEImages/WolframModelPropertiesStatesList.png)

This is identical to using the `"Generation"` property mapped over all generations:
```
In[] := WolframModelPlot /@ (WolframModel[{{1, 2, 3}, {4, 5, 6}, {1,
         4}} -> {{2, 7, 8}, {3, 9, 10}, {5, 11, 12}, {6, 13, 14}, {8,
         12}, {11, 10}, {13, 7}, {14, 9}}, {{1, 1, 1}, {1, 1, 1}, {1,
        1}, {1, 1}, {1, 1}}, 6]["Generation", #] &) /@ Range[0, 6]
```
![WolframModelPropertiesStatesList](READMEImages/WolframModelPropertiesStatesList.png)

In fact `"Generation"` property can be omitted and the index of the generation can be used directly:
```
In[] := WolframModelPlot /@
 WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
      10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
      9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6] /@
  Range[0, 6]
```
![WolframModelPropertiesStatesList](READMEImages/WolframModelPropertiesStatesList.png)

`"StatesList"` shows a compressed version of the evolution. To see how state changes with each applied replacement, use `"AllEventsStatesList"`:
```
In[] := WolframModelPlot /@
 WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
     10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
     9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 3,
  "AllEventsStatesList"]
```
![WolframModelPropertiesAllEventsStatesList](READMEImages/WolframModelPropertiesAllEventsStatesList.png)

Finally, to see a state after a specific event, use `"StateAfterEvent"`:
```
In[] := WolframModelPlot@
 WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
      10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
      9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 6][
  "StateAfterEvent", 42]
```
![WolframModelPropertiesStateAfterEvent](READMEImages/WolframModelPropertiesStateAfterEvent.png)

This is equivalent to taking a corresponding part in the `"AllEventsStatesList"`, but is much faster to compute than the entire list.

#### FinalStatePlot, StatesPlotsList

Instead of explicitly calling `WolframModelPlot`, one can use short-hand properties `"FinalStatePlot"` and `"StatesPlotsList"`:
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
    10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
    9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1,
   1}}, 6, "FinalStatePlot"]
```
![WolframModelPropertiesFinalState](READMEImages/WolframModelPropertiesFinalState.png)

```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
    10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
    9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1,
   1}}, 6, "StatesPlotsList"]
```
![WolframModelPropertiesStatesList](READMEImages/WolframModelPropertiesStatesList.png)

These properties take the same options as `WolframModelPlot`:
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
     10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
     9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}},
  3]["FinalStatePlot", VertexLabels -> Automatic]
```
![WolframModelPropertiesFinalStatePlotVertexLabels](READMEImages/WolframModelPropertiesFinalStatePlotVertexLabels.png)

#### EventsStatesPlotsList

The plotting function corresponding to `"AllEventsStatesList"` is more interesting than the other ones. It plots not only the corresponding states, but also the events that produced each of them:
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
    10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
    9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1,
   1}}, 3, "EventsStatesPlotsList"]
```
![WolframModelPropertiesEventsStatesPlotsList](READMEImages/WolframModelPropertiesEventsStatesPlotsList.png)

Here the dotted gray edges are the ones about to be deleted, whereas the red ones have just been created.

#### AllEventsEdgesList (aka AllExpressions)

`"AllEventsEdgesList"` returns the list of edges throughout history. This is distinct from a catenated `"StateList"`, as the edge will not appear twice if it moved from one generation to the next without being involved in an event.

Compare for instance the output of `"StatesList"` for a system where only one replacement is made per generation
```
In[] := WolframModel[<|"PatternRules" -> {x_?OddQ, y_} :> x + y|>, {1, 2, 4,
  6}, \[Infinity], "StatesList"]
Out[] = {{1, 2, 4, 6}, {4, 6, 3}, {6, 7}, {13}}
```
with the output of `"AllEventsEdgesList"`:
```
In[] := WolframModel[<|"PatternRules" -> {x_?OddQ, y_} :> x + y|>, {1, 2, 4,
  6}, \[Infinity], "AllEventsEdgesList"]
Out[] = {1, 2, 4, 6, 3, 7, 13}
```
Note how 4 and 6 only appear once in the list.

Edge indices from `"AllEventsEdgesList"` are used in various other properties such as [`"AllEventsList"`](#alleventslist--aka-eventslist---generationeventslist) and [`"EventsStatesList"`](#eventsstateslist).

#### AllEventsStatesEdgeIndicesList, StateEdgeIndicesAfterEvent

`"AllEventsStatesEdgeIndicesList"` is similar to `"AllEventsStatesList"`, except instead of actual edges the list it returns contains the indices of edges from `"AllEventsEdgesList"`.
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
    10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
    9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1,
   1}}, 2, "AllEventsStatesEdgeIndicesList"]
Out[] = {{1, 2, 3, 4, 5}, {4, 5, 6, 7, 8, 9, 10, 11, 12, 13}, {5, 8, 9, 10,
  11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21}, {10, 11, 12, 13, 14,
  15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29}}
```

One can easily go back to states
```
In[] := WolframModelPlot /@
 With[{evolution =
    WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
        10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13,
        7}, {14, 9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}},
     3]}, evolution["AllEventsEdgesList"][[#]] & /@
   evolution["AllEventsStatesEdgeIndicesList"]]
```
![WolframModelPropertiesAllEventsStatesList](READMEImages/WolframModelPropertiesAllEventsStatesList.png)

however this representation is useful if one needs to distinguish between identical edges.

Similarly, `"StateEdgeIndicesAfterEvent"` is a index analog of `"StateAfterEvent"`:
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {3, 9,
     10}, {5, 11, 12}, {6, 13, 14}, {8, 12}, {11, 10}, {13, 7}, {14,
     9}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}},
  6]["StateEdgeIndicesAfterEvent", 12]
Out[] = {18, 19, 29, 34, 35, 36, 37, 39, 40, 42, 43, 44, 45, 49, 50, 51, 52, \
53, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, \
71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, \
88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101}
```

#### AllEventsList (aka EventsList), GenerationEventsList

Both of these properties return all replacement events throughout the evolution. The only difference is how the events are arranged. `"AllEventsList"` returns the flat list of all events, whereas `"GenerationEventsList"` splits them into sublists for each generation.
```
In[] := WolframModel[{{1, 2}} -> {{3, 4}, {3, 1}, {4, 1}, {2, 4}}, {{1,
   1}}, 2, "AllEventsList"]
Out[] = {{1, {1} -> {2, 3, 4, 5}}, {1, {2} -> {6, 7, 8, 9}}, {1, {3} -> {10,
    11, 12, 13}}, {1, {4} -> {14, 15, 16, 17}}, {1, {5} -> {18, 19,
    20, 21}}}
```

```
In[] := WolframModel[{{1, 2}} -> {{3, 4}, {3, 1}, {4, 1}, {2, 4}}, {{1,
   1}}, 2, "GenerationEventsList"]
Out[] = {{{1, {1} -> {2, 3, 4, 5}}}, {{1, {2} -> {6, 7, 8,
     9}}, {1, {3} -> {10, 11, 12, 13}}, {1, {4} -> {14, 15, 16,
     17}}, {1, {5} -> {18, 19, 20, 21}}}}
```

The format for the events is
```
{ruleIndex, {indexEdgeIndices} -> {outputEdgeIndices}}
```
where the edge indices refer to expressions from [`"AllEventsEdgesList"`](#alleventsedgeslist--aka-allexpressions-).

#### EventsStatesList

`"EventsStatesList"` just produces a list of (event, state) pairs, where state is the complete state right after this event is applied. Events are the same as generated by `"AllEventsList"`, and the states are represented as edge indices as in `"AllEventsStatesEdgeIndicesList"`.
```
In[] := WolframModel[{{1, 2}} -> {{3, 4}, {3, 1}, {4, 1}, {2, 4}}, {{1,
   1}}, 2, "EventsStatesList"]
Out[] = {{{1, {1} -> {2, 3, 4, 5}}, {2, 3, 4,
   5}}, {{1, {2} -> {6, 7, 8, 9}}, {3, 4, 5, 6, 7, 8,
   9}}, {{1, {3} -> {10, 11, 12, 13}}, {4, 5, 6, 7, 8, 9, 10, 11, 12,
   13}}, {{1, {4} -> {14, 15, 16, 17}}, {5, 6, 7, 8, 9, 10, 11, 12,
   13, 14, 15, 16, 17}}, {{1, {5} -> {18, 19, 20, 21}}, {6, 7, 8, 9,
   10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21}}}
```

#### EdgeCreatorEventIndices (aka CreatorEvents), EdgeDestroyerEventIndices (aka DestroyerEvents)

And event *destroys* the edges in its input, and *creates* the edges in its output. Creator and destroyer events for each edge can be obtained with `EdgeCreatorEventIndices` and `EdgeDestroyerEventIndices` properties.

As an example, for a simple rule that splits each edge in two, one can see that edges are created in pairs:
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1,
   1}}, 4, "EdgeCreatorEventIndices"]
Out[] = {0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, \
11, 12, 12, 13, 13, 14, 14, 15, 15}
```
and destroyed one-by-one:
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1,
   1}}, 4, "EdgeDestroyerEventIndices"]
Out[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, \[Infinity], \
\[Infinity], \[Infinity], \[Infinity], \[Infinity], \[Infinity], \
\[Infinity], \[Infinity], \[Infinity], \[Infinity], \[Infinity], \
\[Infinity], \[Infinity], \[Infinity], \[Infinity], \[Infinity]}
```

Here 0 refers to the initial state, and `\[Infinity]` means an expression was never destroyed by any event (and thus appears in the final state). Thus a simple way to obtain a `"FinalState"` is to pick all expressions which destroyer event is `\[Infinity]`:
```
In[] := With[{evolution =
   WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4]},
 evolution["AllEventsEdgesList"][[
  First /@ Position[
    evolution["EdgeDestroyerEventIndices"], \[Infinity]]]]]
Out[] = {{1, 9}, {9, 5}, {5, 10}, {10, 3}, {3, 11}, {11, 6}, {6, 12}, {12,
  2}, {2, 13}, {13, 7}, {7, 14}, {14, 4}, {4, 15}, {15, 8}, {8,
  16}, {16, 1}}
```
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 1}}, 4][-1]
Out[] = {{1, 9}, {9, 5}, {5, 10}, {10, 3}, {3, 11}, {11, 6}, {6, 12}, {12,
  2}, {2, 13}, {13, 7}, {7, 14}, {14, 4}, {4, 15}, {15, 8}, {8,
  16}, {16, 1}}
```

#### CausalGraph, LayeredCausalGraph

An event A causes an event B if there exists an edge that was created by A and destroyed by B. If we then consider all relationships between events, we can create a causal graph. In a causal graph vertices correspond to events, and causal graph edges correspond to the set edges (aka expressions).

For example if we consider our simple arithmetic model `{a_, b_} :> a + b` starting from `{3, 8, 8, 8, 2, 10, 0, 9, 7}` we get a causal graph which quite clearly describes what's going on (each event here is labeled with explicit values for a and b):
```
In[] := With[{evolution =
   WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {3, 8, 8, 8,
     2, 10, 0, 9, 7}, \[Infinity]]},
 With[{causalGraph = evolution["CausalGraph"]},
  Graph[causalGraph,
   VertexLabels ->
    Thread[VertexList[causalGraph] ->
      Map[evolution["AllEventsEdgesList"][[#]] &,
       Last /@ evolution["AllEventsList"], {2}]]]]]
```
![WolframModelPropertiesArithmeticCausalGraph](READMEImages/WolframModelPropertiesArithmeticCausalGraph.png)

Here is an example for a hypergraph model (which is considerably harder to understand):
```
In[] := WolframModel[{{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{3, 7, 8}, {9, 2,
     10}, {11, 12, 5}, {13, 14, 6}, {7, 12}, {11, 9}, {13, 10}, {14,
     8}}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1,
   1}}, 20, "CausalGraph"]
```
![WolframModelPropertiesHypergraphModelCausalGraph](READMEImages/WolframModelPropertiesHypergraphModelCausalGraph.png)

`"LayeredCausalGraph"` generations the same graph but layers events generation-by-generation. For example, for our arithmetic causal graph, note how it's arranged differently from an example above:
```
In[] := With[{evolution =
   WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {3, 8, 8, 8,
     2, 10, 0, 9, 7}, \[Infinity]]},
 With[{causalGraph = evolution["LayeredCausalGraph"]},
  Graph[causalGraph,
   VertexLabels ->
    Thread[VertexList[causalGraph] ->
      Map[evolution["AllEventsEdgesList"][[#]] &,
       Last /@ evolution["AllEventsList"], {2}]]]]]
```
![WolframModelPropertiesArithmeticLayeredCausalGraph](READMEImages/WolframModelPropertiesArithmeticayeredCausalGraph.png)

Furthermore, if we include the initial condition as a "fake" event (see [`"IncludeBoundaryEvents"`](#includeboundaryevents) option for more information), note how slices through the causal graph correspond to states from the `"StatesList"`:
```
In[] := With[{evolution =
   WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {3, 8, 8, 8,
     2, 10, 0, 9, 7}, \[Infinity]]},
 With[{causalGraph =
    evolution["LayeredCausalGraph",
     "IncludeBoundaryEvents" -> "Initial"]},
  Graph[causalGraph,
   VertexLabels ->
    Thread[VertexList[causalGraph] ->
      Map[evolution["AllEventsEdgesList",
          "IncludeBoundaryEvents" -> "Initial"][[#]] &,
       Last /@ evolution["AllEventsList",
         "IncludeBoundaryEvents" -> "Initial"], {2}]],
   Epilog -> {Red, Dotted,
     Table[Line[{{-10, k}, {10, k}}], {k, 0.5, 4.5}]}]]]
```
![WolframModelPropertiesArithmeticLayeredCausalGraphFoliated](READMEImages/WolframModelPropertiesArithmeticLayeredCausalGraphFoliated.png)

```
In[] := WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {3, 8, 8, 8, 2,
  10, 0, 9, 7}, \[Infinity], "StatesList"]
Out[] = {{3, 8, 8, 8, 2, 10, 0, 9, 7}, {7, 11, 16, 12, 9}, {9, 18, 28}, {28,
  27}, {55}}
```

`"CausalGraph"` property accepts the same options as `Graph` as was demonstrated above with `VertexLabels`.

#### AllEventsRuleIndices

`"AllEventsRuleIndices"` returns which rule was used for each event (the same can be obtained by mapping `First` over `"AllEventsList"`):
```
In[] := WolframModel[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2, 3}}, {{1,
     2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, {{1, 1,
   1}}, 4, "AllEventsRuleIndices"]
Out[] = {1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2}
```

A neat example of using `"AllEventsRuleIndices"` is coloring events in a causal graph differently depending on which rule they correspond to. With this visualization one can see, for instance, that the outputs of the second rule in the example above are never used in any further inputs:
```
In[] := With[{evolution =
   WolframModel[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2,
        3}}, {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, {{1, 1, 1}}, 6]},
  With[{causalGraph = evolution["LayeredCausalGraph"]},
  Graph[causalGraph,
   VertexStyle ->
    Thread[VertexList[causalGraph] ->
      Replace[evolution["AllEventsRuleIndices"], {1 -> Black,
        2 -> White}, {1}]], VertexSize -> Medium]]]
```
![WolframModelPropertiesCausalGraphColoring](READMEImages/WolframModelPropertiesCausalGraphColoring.png)

#### EdgeGenerationsList (aka ExpressionGenerations), AllEventsGenerationsList (aka EventGenerations or EventGenerationsList)

`"EdgeGenerationsList"` yields the list generation numbers (numbers of predecessor layers) for each edge in `"AllEventsEdgesList"`. `"AllEventsGenerationsList"` gives the same for events. The generation of an event is the same as the generation of edges it produces as output.

Here edges of different generations are colored differently:
```
In[] := WolframModel[{{1, 2}, {1, 3}, {1, 4}} -> {{2, 2}, {3, 2}, {3, 4}, {3,
    5}}, {{1, 1}, {1, 1}, {1, 1}}, 5, "EdgeGenerationsList"]
Out[] = {0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, \
5, 5, 5, 5}
```
```
In[] := With[{evolution =
   WolframModel[{{1, 2}, {1, 3}, {1, 4}} -> {{2, 2}, {3, 2}, {3,
       4}, {3, 5}}, {{1, 1}, {1, 1}, {1, 1}}, 5]},
 MapThread[
  WolframModelPlot[#, EdgeStyle -> #2] &, {evolution["StatesList"],
   Replace[evolution[
        "EdgeGenerationsList"][[#]] & /@ (evolution[
         "StateEdgeIndicesAfterEvent", #] &) /@
      Prepend[0]@Accumulate@evolution["GenerationEventsCountList"],
    g_ :> ColorData["Rainbow"][g/5], {2}]}]]
```
![WolframModelPropertiesEdgeGenerationsListColoring](READMEImages/WolframModelPropertiesEdgeGenerationsListColoring.png)

Event generations correspond to layers in `"LayeredCausalGraph"`:
```
In[] := WolframModel[{{1, 2}, {1, 3}, {1, 4}} -> {{2, 2}, {3, 2}, {3, 4}, {3,
    5}}, {{1, 1}, {1, 1}, {1, 1}}, 5, "AllEventsGenerationsList"]
Out[] = {1, 2, 3, 4, 5, 5}
```
```
In[] := WolframModel[{{1, 2}, {1, 3}, {1, 4}} -> {{2, 2}, {3, 2}, {3, 4}, {3,
    5}}, {{1, 1}, {1, 1}, {1, 1}}, 5, "LayeredCausalGraph"]
```
![WolframModelPropertiesAllEventsGenerationsListCausalGraph](READMEImages/WolframModelPropertiesAllEventsGenerationsListCausalGraph.png)

#### TerminationReason

`"TerminationReason"` shows why the evaluation of the model was stopped. This is particularly useful if multiple [stopping conditions](#step-limiters) are specified.

All possible values are:
* `"MaxEvents"`, `"MaxGenerations"`, `"MaxVertices"`, `"MaxVertexDegree"` and `"MaxEdges"` correspond directly to step limiters.
* `"FixedPoint"` means there were no more matches possible to rule inputs.
* `"TimeConstraint"` could occur if a [`"TimeConstraint"`](#timeconstraint) option was used.
* `"Aborted"` would occur if the evaluation was manually interrupted (i.e., with ⌘. on a Mac). In that case a partially computed evolution object will still be returned.

As an example, in our arithmetic model from before a `"FixedPoint"` is reached (which is why we can use `Infinity` as the number of steps):
```
In[] := WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {3, 8, 8, 8, 2,
   10, 0, 9, 7}, \[Infinity]]["TerminationReason"]
Out[] = "FixedPoint"
```

And if we manually abort the evolution, we could get something like this:
```
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {1, 4}} -> {{2, 7, 8}, {5, 9,
    10}, {6, 11, 12}, {13, 3, 14}, {8, 13}, {9, 7}, {10, 12}, {14,
    11}}, {{1, 1, 1}, {1, 1, 1}, {1, 1}, {1, 1}, {1, 1}}, 100]
⌘.
```
![WolframModelAbortedEvolutionObject](READMEImages/WolframModelAbortedEvolutionObject.png)

#### GenerationsCount, TotalGenerationsCount, PartialGenerationsCount, CompleteGenerationsCount (aka MaxCompleteGeneration), GenerationComplete

`"TotalGenerationsCount"` returns the largest generation of any edge during the evolution:
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, <|
  "MaxEvents" -> 42|>, "TotalGenerationsCount"]
Out[] = 5
```

`"PartialGenerationsCount"` return the number of generations that are "completely done". That is, no more matches can be made involving this or earlier generations. If the default [evaluation order](#eventorderingfunction) is used, this can only be 0 (if we are in the middle of a step) or 1 (if we just finished the step). However, it gets much more interesting if a different event order is used. For a random evolution, for instance, one can get:
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, <|
  "MaxEvents" -> 42|>, "EventOrderingFunction" -> "Random"]
```
![WolframModelPartialGenerationsCountRandomObject](READMEImages/WolframModelPartialGenerationsCountRandomObject.png)

Note, in this case, only 2 generations are complete, and 7 are partial. That happens because the states grow with each generation, so it becomes more likely for a random choice to pick an edge from a later generation, thus earlier ones are left unevolved.

`"CompleteGenerationsCount"` is simply a difference of `"TotalGenerationsCount"` and `"PartialGenerationsCount"`, and `"GenerationsCount"` is equivalent to `{"CompleteGenerationsCount", "PartialGenerationsCount"}`.

`"GenerationComplete"` takes a generation number as an argument, and gives `True` or `False` depending on whether that particular generation is complete.
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, <|
   "MaxEvents" -> 42|>]["GenerationComplete", 5]
Out[] = False
```

#### AllEventsCount (aka EventsCount), GenerationEventsCountList

`"AllEventsCount"` just returns the overall number of events throughout the evolution (the `Length` of `"AllEventsList"`).

`"GenerationEventsCountList"` gives the number of events per each generation (`Length` mapped over `"GenerationEventsList"`):
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1,
   1}}, 5, "GenerationEventsCountList"]
Out[] = {1, 3, 9, 27, 81}
```

#### VertexCountList, EdgeCountList

`"VertexCountList"` and `"EdgeCountList"` return counts of vertices and edges respectively in each state of `"StatesList"`. They are useful to see how quickly a particular system grows.

```
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{6, 6, 3}, {2, 6, 2}, {6, 4,
    2}, {5, 3, 6}}, {{1, 1, 1}, {1, 1, 1}}, 10, "VertexCountList"]
Out[] = {1, 2, 4, 8, 14, 27, 49, 92, 171, 324, 622}
```

```
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{6, 6, 3}, {2, 6, 2}, {6, 4,
    2}, {5, 3, 6}}, {{1, 1, 1}, {1, 1, 1}}, 10, "EdgeCountList"]
Out[] = {2, 4, 8, 16, 28, 54, 98, 184, 342, 648, 1244}
```

#### FinalDistinctElementsCount (aka AtomsCountFinal), FinalEdgeCount (aka ExpressionsCountFinal)

These properties are similar to corresponding `*List` ones, except we don't have `"FinalVertexCount"` and instead have `"FinalDistinctElementsCount"` (we should have `"FinalVertexCount"` and `"FinalDistinctElementsCountList"`, but they are not currently implemented).

The difference is that `"VertexCountList"` counts expressions of level 2 in the states whereas `"FinalDistinctElementsCount"` counts all expressions matching `_ ? AtomQ`. The difference becomes apparent for edges which contain non-trivially nested lists.

For example, consider a rule that performs a non-trivial nesting:
```
In[] := WolframModel[<|
  "PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2,
       a - 2}}}|>, {{1}}, 7, "VertexCountList"]
Out[] = {1, 3, 6, 10, 15, 21, 28, 36}
```

```
In[] := WolframModel[<|
    "PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2,
         a - 2}}}|>, {{1}}, #, "FinalDistinctElementsCount"] & /@
 Range[0, 7]
Out[] = {1, 4, 9, 13, 17, 21, 25, 29}
```

To understand why this is happening, consider the state after one step:
```
In[] := WolframModel[<|
  "PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2,
       a - 2}}}|>, {{1}}, 1, "FinalState"]
Out[] = {{2}, {0}, {{3, -1}}}
```

This state has 3 vertices (distinct level-2 expressions): `2`, `0` and `{3, -1}`, but 4 atoms: `2`, `0`, `3` and `-1`. This distinction does not usually come up in our models since vertices are atoms are usually the same thing, but it is important in exotic cases like this.

#### AllEventsDistinctElementsCount (aka AtomsCountTotal), AllEventsEdgesCount (aka ExpressionsCountTotal)

These properties are similar to `"FinalDistinctElementsCount"` and `"FinalEdgeCount"`, except they count atoms and edges throughout the entire evolution instead of just in the final step.

For instance,
```
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{6, 6, 3}, {2, 6, 2}, {6, 4,
    2}, {5, 3, 6}}, {{1, 1, 1}, {1, 1,
   1}}, 10, {"AllEventsDistinctElementsCount", "AllEventsEdgesCount"}]
Out[] = {622, 2486}
```

#### Rules

`"Rules"` just stores the rules in exactly the same way they were entered as an input to `WolframModel`.
```
In[] := WolframModel[<|
   "PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2,
        a - 2}}}|>, {{1}}, 1]["Rules"]
Out[] = <|"PatternRules" -> {{a_}} :> {{a + 1}, {a - 1}, {{a + 2, a - 2}}}|>
```

This is useful for display in the information box of the evolution object, and if one needs to reproduce an evolution object the input for which is no longer available.

### Options

#### VertexNamingFunction

`"VertexNamingFunction"` controls the names chosen for vertices, particularly the newly created ones. It can take three values: `None`, `Automatic` and `All`.

`None` does not do anything, the vertices in the initial condition are left as-is, and the newly created vertices use symbol names as, i.e., `Module[{v}, v]` would generate.
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{v1,
   v1}}, 2, "StatesList", "VertexNamingFunction" -> None]
Out[] = {{{v1, v1}}, {{v1, v256479}, {v1, v256479}, {v256479, v1}}, {{v1,
   v256480}, {v1, v256480}, {v256480, v256479}, {v1, v256481}, {v1,
   v256481}, {v256481, v256479}, {v256479, v256482}, {v256479,
   v256482}, {v256482, v1}}}
```

`All` renames all vertices as sequential integers, including the ones in initial condition, and including ones manually generated in [pattern rules](#pattern-rules).
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{v1,
   v1}}, 2, "StatesList", "VertexNamingFunction" -> All]
Out[] = {{{1, 1}}, {{1, 2}, {1, 2}, {2, 1}}, {{1, 3}, {1, 3}, {3, 2}, {1,
   4}, {1, 4}, {4, 2}, {2, 5}, {2, 5}, {5, 1}}}
```

`Automatic` only renames newly created vertices with non-previouslly-used integers, and leaves the initial condition as-is. It does nothing in the case of [pattern rules](#pattern-rules).
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{v1,
   v1}}, 2, "StatesList", "VertexNamingFunction" -> Automatic]
Out[] = {{{v1, v1}}, {{v1, 1}, {v1, 1}, {1, v1}}, {{v1, 2}, {v1, 2}, {2,
   1}, {v1, 3}, {v1, 3}, {3, 1}, {1, 4}, {1, 4}, {4, v1}}}
```

#### IncludePartialGenerations

In case partial generations were generated, they can be automatically dropped by setting `"IncludePartialGenerations" -> False`. Compare for instance
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, <|
  "MaxEvents" -> 42|>]
```
![WolframModelEvolutionObjectWithPartialGenerations](READMEImages/WolframModelEvolutionObjectWithPartialGenerations.png)
with
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 1}}, <|
  "MaxEvents" -> 42|>, "IncludePartialGenerations" -> False]
```
![WolframModelEvolutionObjectWithPartialGenerationsDropped](READMEImages/WolframModelEvolutionObjectWithPartialGenerationsDropped.png)

One neat use of this is producing a uniformly random evolution for a complete number of generations:
```
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{6, 6, 3}, {2, 6, 2}, {6, 4,
    2}, {5, 3, 6}}, {{1, 1, 1}, {1, 1, 1}}, <|
  "MaxEvents" -> 10000|>, "FinalStatePlot",
 "EventOrderingFunction" -> "Random",
 "IncludePartialGenerations" -> False]
```
![WolframModelCompleteUniformRandomEvolutionPlot](READMEImages/WolframModelCompleteUniformRandomEvolutionPlot.png)

#### IncludeBoundaryEvents

`"IncludeBoundaryEvents"` allows one to include "fake" initial and final events in properties such as `"CausalGraph"`. It does not affect the evolution itself, and has no effect on the evolution object. It has 4 settings: `None`, `"Initial"`, `"Final"` and `All`.

We have already [demonstrated](#causalgraph-layeredcausalgraph) it previously for our arithmetic model. Here is an example with the final "event" included as well (event labels are kept for reference):
```
In[] := With[{evolution =
   WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {3, 8, 8, 8,
     2, 10, 0, 9, 7}, \[Infinity]]},
 With[{causalGraph =
    evolution["LayeredCausalGraph", "IncludeBoundaryEvents" -> All]},
  Graph[causalGraph,
   VertexLabels ->
    Thread[VertexList[causalGraph] ->
      Map[evolution["AllEventsEdgesList",
          "IncludeBoundaryEvents" -> All][[#]] &,
       Last /@ evolution["AllEventsList",
         "IncludeBoundaryEvents" -> All], {2}]]]]]
```
![WolframModelIncludeBoundaryEventsCausalGraph](READMEImages/WolframModelIncludeBoundaryEventsCausalGraph.png)

Properties like `"AllEventsList"` are affected as well:
```
In[] := WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>, {3, 8, 8, 8, 2,
  10, 0, 9, 7}, \[Infinity], "AllEventsList",
 "IncludeBoundaryEvents" -> "Final"]
Out[] = {{1, {1, 2} -> {10}}, {1, {3, 4} -> {11}}, {1, {5,
    6} -> {12}}, {1, {7, 8} -> {13}}, {1, {9, 10} -> {14}}, {1, {11,
    12} -> {15}}, {1, {13, 14} -> {16}}, {1, {15,
    16} -> {17}}, {\[Infinity], {17} -> {}}}
```

#### Method

There are two implementations available: one written in Wolfram Language (`Method -> "Symbolic"`), one in C++ (`Method -> "LowLevel"`).

The Wolfram Language implementation permutes the left-hand sides of the rules in all possible ways and uses `Replace` a specified number of times to perform evolution. This works well for small graphs and small rule inputs, but it slows down with the number of edges in the graph and has exponential complexity in rule size.

The C++ implementation, on the other hand, keeps an index of all possible rule matches and updates it after every replacement. The reindexing algorithm looks only at the local region of the graph close to the rewrite site, thus time complexity does not depend on the graph size as long as vertex degrees are small. The downside is that it has exponential complexity (both in time and memory) in the vertex degrees. Currently, it also does not work for non-local rules (i.e., rule inputs that do not form a connected hypergraph) and rules that are not hypergraph rules (i.e., pattern rules that have non-trivial nesting or conditions).

C++ implementation is used by default for supported systems, and is particularly useful if:
* Vertex degrees are expected to be small.
* Evolution needs to be done for a large number of steps `> 100`, it is possible to produce states with up to `10^6` edges or more.

It should not be used, however, if vertex degrees can grow large. For example
```
In[] := WolframModel[{{{0}} -> {{0}, {0}, {0}}, {{0}, {0}, {0}} -> {{0}}}, \
{{0}}, <|"MaxEvents" -> 30|>, Method -> "LowLevel"]
```
![WolframModelSlowLowLevelObject](READMEImages/WolframModelSlowLowLevelObject.png)
takes almost 10 seconds in C++ implementation, and less than 1/10th of a second in the Wolfram Language implementation:
```
In[] := WolframModel[{{{0}} -> {{0}, {0}, {0}}, {{0}, {0}, {0}} -> {{0}}}, \
{{0}}, <|"MaxEvents" -> 30|>, Method -> "Symbolic"]
```
![WolframModelFastSymbolicObject](READMEImages/WolframModelFastSymbolicObject.png)

On the other hand, Wolfram Language implementation should be used if:
* A large number of small rules with unknown behavior needs to be simulated for a small number of steps.
* Vertex degrees are expected to be large, rules are non-local, or pattern rules with non-trivial nesting or conditions are used.

#### TimeConstraint

`TimeConstraint` option allows one to stop the evolution early. If an evolution object is requested, it will return a partial result, otherwise, it will just give `$Aborted`.
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1,
   1}}, \[Infinity], TimeConstraint -> 1]
```
![WolframModelTimeConstrainedEvolutionObject](READMEImages/WolframModelTimeConstrainedEvolutionObject.png)

#### EventOrderingFunction

In many `WolframModel` systems multiple matches are possible at any given step. As an example, two possible replacements are possible in the system below from the initial condition:
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}, {2, 2}}, <|
  "MaxEvents" -> 1|>, "EventsStatesPlotsList"]
```
![WolframModelNonoverlappingEventOrderingOldest](READMEImages/WolframModelNonoverlappingEventOrderingOldest.png)

```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {3, 2}}, {{1, 2}, {2, 2}}, <|
  "MaxEvents" -> 1|>, "EventsStatesPlotsList",
 "EventOrderingFunction" -> "NewestEdge"]
```
![WolframModelNonoverlappingEventOrderingNewest](READMEImages/WolframModelNonoverlappingEventOrderingNewest.png)

In this particular, the so-called non-overlapping system, the order of replacements does not matter, as regardless of order the same final state (upto the renaming of vertices) will be produced for the same fixed number of generations. This will always be the case if there is only a single edge on the left-hand side of the rule:
```
In[] := WolframModel[{{1, 2}} -> {{1, 3}, {1, 3}, {3, 2}}, {{1, 2}, {2, 2}},
   3, "FinalStatePlot", "EventOrderingFunction" -> #] & /@ {Automatic,
   "Random"}
```
![WolframModelNonoverlappingRandom](READMEImages/WolframModelNonoverlappingRandom.png)

For some systems, however, the order of replacements does matter, and non-equivalent final states would be produced for different orders even if a fixed number of generations is requested:
```
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{4, 2}, {4, 1}, {2, 1}, {3,
    4}}, {{1, 2}, {2, 3}, {3, 4}, {4, 1}}, 5, "FinalStatePlot"]
```
![WolframModelOverlappingLeastRecent](READMEImages/WolframModelOverlappingLeastRecent.png)

```
In[] := WolframModel[{{1, 2}, {2, 3}} -> {{4, 2}, {4, 1}, {2, 1}, {3,
    4}}, {{1, 2}, {2, 3}, {3, 4}, {4, 1}}, 5, "FinalStatePlot",
 "EventOrderingFunction" -> "RuleOrdering"]
```
![WolframModelOverlappingRuleOrdering](READMEImages/WolframModelOverlappingRuleOrdering.png)

In case like that it is important to be able to specify the desired evolution order, which is what `"EventOrderingFunction"` option is for. `"EventOrderingFunction"` is specified as a list of sorting criteria such as the default `{"LeastRecentEdge", "RuleOrdering", "RuleIndex"}`. Note that most individual sorting criteria are insufficient to distinguish between all available matches. If multiple matches remain after exchausting all sorting criteria, one will be chosen uniformly at random (which is why `{}` works as a shorthand for `"Random"`).

Possible sorting criteria are:
* `"OldestEdge"`: greedely select the edge in the set closest to the beginning of the list (which would typically correspond to the oldest edge). Note, within a single-event output, the edges are assumed oldest-to-newest left-to-right as written on the right-hand side of the rule. After this criteria, a fixed ***set*** of edges will be chosen, but different orderings of that set might be possible (which could allow for multiple non-equivalent matches).

* `"NewestEdge"`: similar to `"OldestEdge"` except edges are chosen from the end of the list rather than from the beginning.

* `"LeastRecentEdge"`: this is similar to `"OldestEdge"`, but instead of greedely choosing the oldest edges, it instead avoids choosing new ones. The difference is best demonstrated in an example:
```
In[] := WolframModel[{{x, y}, {y, z}} -> {}, {{1, 2}, {a, b}, {b, c}, {2,
     3}}, <|"MaxEvents" -> 1|>, "AllEventsList",
   "EventOrderingFunction" -> #] & /@ {"OldestEdge",
  "LeastRecentEdge"}
Out[] = {{{1, {1, 4} -> {}}}, {{1, {2, 3} -> {}}}}
```

    Note that in this example `"OldestEdge"` has select edges the first and the last edge, whereas `"LeastRecentEdge"` in an attempt to avoid the most "recent" last edge has select the second and the third ones. In this case, similarly to `"OldestEdge"`, a fixed set of edges will be chosen, but potentially in different orders.

* `"LeastOldEdge"`: similar to `"LeastRecentEdge"`, but avoids old edges instead of avoiding new ones.

    Note that counterintuitively `"OldestEdge"` sorting is not equivalent to the reverse of `"NewestEdge"` sorting, it is actually equivalent to the reverse of `"LeastOldEdge"`. Similarly, `"NewestEdge"` is the reverse of `"LeastRecentEdge"`.

* `"RuleOrdering"`: similarly to `"OldestEdge"` greedely chooses edges from the beginning of the list, however unlike `"OldestEdge"` which would pick the oldest edge with *any* available matches, it chooses edges in the order the left-hand side of (any) rule is written. The difference is best demonstrated in an example:
```
In[] := WolframModel[{{x, y}, {y, z}} -> {}, {{b, c}, {1, 2}, {a, b}, {2,
     3}}, <|"MaxEvents" -> 1|>, "AllEventsList",
   "EventOrderingFunction" -> #] & /@ {"OldestEdge", "RuleOrdering"}
Out[] = {{{1, {1, 3} -> {}}}, {{1, {2, 4} -> {}}}}
```

    Note how `"RuleOrdering"` has selected the second edge first because it matches to the first rule input while the first edge does not.

In this case a specific ordered sequence of edges will be matched (including its permutation). However, multiple matches might still be possible if multiple rules exist which match that sequence.

* `"ReverseRuleOrdering"`: as the name suggests, this is just the reverse of `"RuleOrdering"`.

* `"RuleIndex"`: this simply means it will attempt to match the first rule first, and only if no matches to the first rule are possible, it will go to the second rule, etc.

* `"ReverseRuleIndex"`: similar to `"RuleIndex"`, but reversed as the name suggests.

* `"Random"`: this will select a single match uniformly at random. This is possible to do efficiently because the C++ implementation of `WolframModel` (the only one that supported `"EventOrderingFunction"`) keeps track of all possible matches at any point during the evolution. This is guaranteed to select a single match, so the remainder of the sorting criteria list is ignored. It can also be omitted because the random event will always be chosen if provided sorting criteria are insufficient. The seeding can be controlled with `SeedRandom`, however, the result will depend on your platform (Mac/Linux/Windows) and the specific build (version) of `SetReplace`.

As a neat example, here is the output of all individual sorting criteria (default sorting criteria are appended to disambiguate):
```
In[] := WolframModel[{{{1, 2}, {1, 3}, {1, 4}} -> {{5, 6}, {6, 7}, {7, 5}, {5,
         7}, {7, 6}, {6, 5}, {5, 2}, {6, 3}, {7, 4}, {2, 7}, {4,
        5}}, {{1, 2}, {1, 3}, {1, 4}, {1, 5}} -> {{2, 3}, {3,
        4}}}, {{1, 1}, {1, 1}, {1, 1}}, <|"MaxEvents" -> 30|>,
    "EventOrderingFunction" -> {#, "LeastRecentEdge", "RuleOrdering",
      "RuleIndex"}]["FinalStatePlot",
   PlotLabel -> #] & /@ {"OldestEdge", "LeastOldEdge",
  "LeastRecentEdge", "NewestEdge", "RuleOrdering",
  "ReverseRuleOrdering", "RuleIndex", "ReverseRuleIndex", "Random"}
```
![WolframModelAllEventOrderingFunctions](READMEImages/WolframModelAllEventOrderingFunctions.png)

## WolframModelPlot (aka HypergraphPlot)

## RulePlot of WolframModel

## Utility Functions

### GeneralizedGridGraph

### HypergraphAutomorphismGroup

### HypergraphUnifications

### WolframPhysicsProjectStyleData

# Physics Applications

A hypothesis is that space-time at the fundamental Planck scale might be represented as a network that can be produced by a system similar to the one this package implements.

This idea was first proposed in Stephen Wolfram's [A New Kind Of Science](https://www.wolframscience.com/nks/chap-9--fundamental-physics/).

The system here is not the same (the matching algorithm does not constrain vertex degrees), but it follows the same principles.
