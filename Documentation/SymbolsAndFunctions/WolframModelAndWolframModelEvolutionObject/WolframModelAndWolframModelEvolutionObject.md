###### [Symbols and Functions](/README.md#symbols-and-functions) >

# WolframModel and WolframModelEvolutionObject

[Rule Specification](#rule-specification) | [Automatic Initial State](#automatic-initial-state) | [Step Limiters](#wolframmodel-step-limiters) | [Properties](#properties) | [Options](#options)

**`WolframModel`** is the primary function of the package. It provides tools for the generation and analysis of set substitution systems. It can compute many different properties of the evolution and has many different options, which we describe in the corresponding subsections.

The most basic way to call it is

```wl
In[] := WolframModel[rule, initial set, step count]
```

For example,

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}},
 {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 10]
```

<img src="/Documentation/Images/EvolutionObject10Steps.png" width="493">

Note that this call is different from the [`SetReplace`](../SetReplace*.md) function in a variety of ways:

* The order of arguments is switched, the rule goes first.
* The rule is specified in the "anonymous" form ([`ToPatternRules`](../ToPatternRules.md) is done implicitly).
* The number of steps here is the number of generations, which is equivalent to steps of [`SetReplaceAll`](../SetReplace*.md). Here each edge can have at most 10 generations of predecessors.
* The output is not a final state, but a **`WolframModelEvolutionObject`** containing the entire evolution (similar to [`SetReplaceList`](../SetReplace*.md) but with additional information about the relationships between edges and the events that produced them. From the information field on that object, one can see that the evolution was done for 10 generations (i.e., the evolution did not terminate early), and 109 replacements (aka events) were made in total. More properties can be computed from an evolution object.

To see the information an evolution object contains, let's make one with a smaller number of generations:

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}},
 {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 3]
```

<img src="/Documentation/Images/EvolutionObject3Steps.png" width="487">

One can easily see its internal structure in its [`InputForm`](https://reference.wolfram.com/language/ref/InputForm.html):

<img src="/Documentation/Images/InputFormOfEvolutionObject.png" width="594">

```wl
Out[] = WolframModelEvolutionObject[<|
  "Version" -> 2,
  "Rules" -> {{1, 2, 3}, {2, 4, 5}} ->
    {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}},
  "MaxCompleteGeneration" -> 3,
  "TerminationReason" -> "MaxGenerationsLocal",
  "AtomLists" -> {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}, {5, 8, 1}, {8, 4,
     2}, {4, 5, 3}, {7, 9, 8}, {9, 6, 4}, {6, 7, 2}, {1, 10, 4}, {10,
     8, 5}, {8, 1, 3}, {4, 11, 7}, {11, 6, 9}, {6, 4, 8}, {5, 12,
     1}, {12, 8, 10}, {8, 5, 4}},
  "EventRuleIDs" -> {0, 1, 1, 1, 1, 1},
  "EventInputs" -> {{}, {1, 2}, {5, 3}, {6, 4}, {7, 8}, {10, 11}},
  "EventOutputs" -> {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10, 11,
     12}, {13, 14, 15}, {16, 17, 18}},
  "EventGenerations" -> {0, 1, 2, 2, 3, 3}|>]
```

The most important part of this [`Association`](https://reference.wolfram.com/language/ref/Association.html) is `"AtomLists"` which includes all set elements (aka expressions or edges) ever created throughout evolution.

In this particular example, it begins with `{1, 2, 3}`, `{2, 4, 5}` and `{4, 6, 7}`, which is the initial set. It is then followed by `{5, 8, 1}`, `{8, 4, 2}` and `{4, 5, 3}` which are the edges created in the first replacement event (the new vertex `8` here is named with the first unused integer, see [`"VertexNamingFunction"`](Options/VertexNamingFunction.md) for details about naming). These edges are followed by four more triples of edges corresponding to the outputs of remaining events.

`"AtomLists"` contains edges from all steps and is by itself insufficient to determine to which step a particular edge belongs. For example, `{5, 8, 1}` only appears in the result after a single step and `{7, 9, 8}` after two steps. Here we use [`"StatesList"`](Properties/States.md) property to demonstrate that:

<img src="/Documentation/Images/StatesListOfEvolutionObject.png" width="613">

```wl
Out[] = {{{1, 2, 3}, {2, 4, 5}, {4, 6, 7}},
 {{4, 6, 7}, {5, 8, 1}, {8, 4, 2}, {4, 5, 3}},
 {{7, 9, 8}, {9, 6, 4}, {6, 7, 2}, {1, 10, 4}, {10, 8, 5}, {8, 1,
   3}},
 {{6, 7, 2}, {8, 1, 3}, {4, 11, 7}, {11, 6, 9}, {6, 4, 8}, {5, 12,
   1}, {12, 8, 10}, {8, 5, 4}}}
```

Note that a set element is not duplicated in `"AtomLists"` if it exists in multiple steps. For example, `{6, 7, 2}` appears in the set after both two and three steps, but it only appears in `"AtomLists"` once because it was never used as an input during the 3rd step.

Other properties of the evolution object describe the relationships between edges and the features of the evolution:

* `"Version"` is the data format of the evolution object. This description is for version 2, which is the first version to support multiway systems. Version 1 does not have the `"Version"` key. The objects of older versions are automatically migrated when they are evaluated.
* `"Rules"` is an exact copy of the corresponding `WolframModel` argument.
* `"MaxCompleteGenerations"` shows the largest generation in which no matches are possible that only involve expressions of this or earlier generations. In this particular case, it is the same as the largest generation of any edge, but it might be different if a more elaborate [step specification](#wolframmodel-step-limiters) is used.
* `"TerminationReason"` shows the reason evaluation was stopped. See the [`"TerminationReason"`](Properties/TerminationReason.md) property for more details.
* `"EventRuleIDs"` shows which rule was used for each event. It's rather boring in this particular case, as this example only has one rule. See [Rule Indices for Events](Properties/RuleIndicesForEvents.md) for a more interesting case. The first value, `0`, corresponds to the initial event, which is included in the evolution object but is omitted [by default](Options/IncludeBoundaryEvents.md) when computing properties.
* `"EventInputs"` shows which edge indices from `"AtomLists"` were used in each event. The order corresponds to the input patterns of the rules. The first value, `{}`, again corresponds to the initial event. Note, the same index can appear multiple times in [multiway systems](Options/EventSelectionFunction.md).
* `"EventOutputs"` similarly shows which edge indices from `"AtomLists"` were produced by each event. There are no duplicates in these lists because events always generate new edges.
* `"EventGenerations"` shows how many layers of predecessors a given event has.

A specific property can be requested from an evolution object by supplying it as an argument to the object itself:

<img src="/Documentation/Images/EventsCountOfEvolutionObject.png" width="629">

```wl
Out[] = 109
```

Properties section describes and gives examples for each available property. The full list of them can also be obtained with the `"Properties"` property:

<img src="/Documentation/Images/PropertiesOfEvolutionObject.png" width="619">

```wl
Out[] = {"EvolutionObject", "FinalState", "FinalStatePlot", "StatesList",
  "StatesPlotsList", "EventsStatesPlotsList",
  "AllEventsStatesEdgeIndicesList", "AllEventsStatesList",
  "GenerationEdgeIndices", "Generation", "StateEdgeIndicesAfterEvent",
   "StateAfterEvent", "TotalGenerationsCount",
  "PartialGenerationsCount", "GenerationsCount", "GenerationComplete",
   "AllEventsCount", "GenerationEventsCountList",
  "GenerationEventsList", "FinalDistinctElementsCount",
  "AllEventsDistinctElementsCount", "VertexCountList",
  "EdgeCountList", "FinalEdgeCount", "AllEventsEdgesCount",
  "AllEventsGenerationsList", "ExpressionsEventsGraph", "CausalGraph",
   "LayeredCausalGraph", "TerminationReason", "AllEventsRuleIndices",
  "AllEventsList", "EventsStatesList", "EdgeCreatorEventIndices",
  "EdgeDestroyerEventsIndices", "EdgeDestroyerEventIndices",
  "EdgeGenerationsList", "ExpressionsSeparation", "Properties",
  "Version", "Rules", "CompleteGenerationsCount",
  "AllEventsEdgesList"}
```

Some properties take additional arguments, which can be supplied after the property name:

<img src="/Documentation/Images/StateAfterEventOfEvolutionObject.png" width="691">

```wl
Out[] = {{8, 1, 3}, {5, 12, 1}, {12, 8, 10}, {8, 5, 4}, {2, 13, 11}, {13, 7,
  6}, {7, 2, 9}, {7, 14, 6}, {14, 11, 4}, {11, 7, 8}}
```

A particular generation can be extracted simply by its number (including, i.e., -1 for the final state):

<img src="/Documentation/Images/GenerationOfEvolutionObject.png" width="516">

```wl
Out[] = {{6, 7, 2}, {8, 1, 3}, {4, 11, 7}, {11, 6, 9}, {6, 4, 8}, {5, 12,
  1}, {12, 8, 10}, {8, 5, 4}}
```

If a property does not take any arguments, it can be specified directly in `WolframModel` as the fourth argument:

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}},
 {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 10, "EdgeCountList"]
Out[] = {3, 4, 6, 8, 12, 18, 24, 36, 54, 76, 112}
```

All properties available to use directly in `WolframModel` can be looked up in `$WolframModelProperties` (there are more properties here compared to the list above because some properties are available under multiple names, and only the canonical name is listed above):

```wl
In[] := $WolframModelProperties
Out[] = {"AllEventsCount", "AllEventsDistinctElementsCount",
  "AllEventsEdgesCount", "AllEventsEdgesList",
  "AllEventsGenerationsList", "AllEventsList", "AllEventsRuleIndices",
   "AllEventsStatesEdgeIndicesList", "AllEventsStatesList",
  "AllExpressions", "AtomsCountFinal", "AtomsCountTotal",
  "CausalGraph", "CompleteGenerationsCount", "CreatorEvents",
  "DestroyerEvents", "EdgeCountList", "EdgeCreatorEventIndices",
  "EdgeDestroyerEventIndices", "EdgeDestroyerEventsIndices",
  "EdgeGenerationsList", "EventGenerations", "EventGenerationsList",
  "EventsCount", "EventsList", "EventsStatesList",
  "EventsStatesPlotsList", "EvolutionObject", "ExpressionGenerations",
   "ExpressionsCountFinal", "ExpressionsCountTotal",
  "ExpressionsEventsGraph", "FinalDistinctElementsCount",
  "FinalEdgeCount", "FinalState", "FinalStatePlot",
  "GenerationComplete", "GenerationEventsCountList",
  "GenerationEventsList", "GenerationsCount", "LayeredCausalGraph",
  "MaxCompleteGeneration", "PartialGenerationsCount", "StatesList",
  "StatesPlotsList", "TerminationReason", "TotalGenerationsCount",
  "UpdatedStatesList", "Version", "VertexCountList"}
```

Multiple properties can also be specified in a list (only in `WolframModel`, not in `WolframModelEvolutionObject`):

```wl
In[] = WolframModel[{{1, 2, 3}, {2, 4, 5}} ->
  {{5, 6, 1}, {6, 4, 2}, {4, 5, 3}},
 {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, 10,
 {"EdgeCountList", "VertexCountList"}]
Out[] = {{3, 4, 6, 8, 12, 18, 24, 36, 54, 76, 112},
 {7, 8, 10, 12, 16, 22, 28, 40, 58, 80, 116}}
```

## Rule Specification

### Multiple Rules

Multiple rules can simply be specified as a list of rules:

```wl
In[] := WolframModel[{{{1, 1, 2}} -> {{2, 2, 1}, {2, 3, 2}, {1, 2, 3}},
  {{1, 2, 1}, {3, 4, 2}} -> {{4, 3, 2}}}, {{1, 1, 1}}, 4]
```

<img src="READMEImages/EvolutionObjectFromMultipleRules.png" width="488">

To see which rules were used for each replacement:

<img src="READMEImages/AllEventsRuleIndicesOfEvolutionObject.png" width="708">

```wl
Out[] = {1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2}
```

### Pattern Rules

Pattern rules (i.e., the kind of rules used in the [`SetReplace`](../SetReplace*.md) function) can be specified as well. As an example, previously described call to [`SetReplaceList`](../SetReplace*.md) can be reproduced as

```wl
In[] := WolframModel[<|"PatternRules" -> {a_, b_} :> a + b|>,
 {1, 2, 5, 3, 6}, Infinity, "AllEventsStatesList"]
Out[] = {{1, 2, 5, 3, 6}, {5, 3, 6, 3}, {6, 3, 8}, {8, 9}, {17}}
```

One can even add conditions spanning multiple expressions:

```wl
In[] := WolframModel[<|"PatternRules" -> {a_, b_} /; a > b :> a - b|>,
 {1, 1, 5, 3, 6}, Infinity, "AllEventsStatesList"]
Out[] = {{1, 1, 5, 3, 6}, {1, 3, 6, 4}, {6, 4, 2}, {2, 2}}
```

## Automatic Initial State

An initial state consisting of an appropriate number of (hyper) self-loops can be automatically produced for anonymous (non-pattern) rules. Here we evolve the system for 0 steps and ask the evolution object for the 0-th generation aka the initial state:

```wl
In[] := WolframModel[{{1, 2}, {1, 2}} -> {{3, 2}, {3, 2}, {2, 1}, {1, 3}},
  Automatic, 0][0]
Out[] = {{1, 1}, {1, 1}}
```

That even works for multiple rules in which case the loops are chosen in such a way that any of the rules can match:

```wl
In[] := WolframModel[{{{1, 2}, {1, 2}} ->
    {{3, 2}, {3, 2}, {2, 1, 3}, {2, 3}},
   {{2, 1, 3}, {2, 3}} -> {{2, 1}, {1, 3}}}, Automatic, 0][0]
Out[] = {{1, 1}, {1, 1}, {1, 1, 1}}
```

Note that because different patterns can be matched to the same symbol, this initial state is guaranteed to match the rules at least once (no guarantees after that).

## Step Limiters

The standard numeric argument to `WolframModel` specifies the number of generations:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}},
 {{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6,
   3}}, 6, "FinalStatePlot"]
```

<img src="/Documentation/Images/MaxGenerationsFinalStatePlot.png" width="478">

Alternatively, an [`Association`](https://reference.wolfram.com/language/ref/Association.html) can be used to specify a more elaborate limiting condition:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}},
 {{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6,
   3}},
 <|"MaxVertices" -> 300, "MaxEvents" -> 200|>, "FinalStatePlot"]
```

<img src="/Documentation/Images/MaxVerticesFinalStatePlot.png" width="478">

Note that the final state here is "less symmetric" because its last generation is incomplete (more on that [later](../UtilityFunctions/HypergraphAutomorphismGroup.md)). Such incomplete generations can be automatically trimmed by setting [`"IncludePartialGenerations" -> False`](Options/IncludePartialGenerations.md).

One can also see the presence of an incomplete generation by looking at the evolution object (note `5...6` which means 5 generations are complete, and 1 is not). Expanding the object's information, one can also see that in this particular case the evolution was terminated because `"MaxVertices"` (not `"MaxEvents"`) condition was reached:

```wl
In[] := WolframModel[{{1, 2, 3}, {4, 5, 6}, {2, 5}, {5, 2}} ->
  {{7, 1, 8}, {9, 3, 10}, {11, 4, 12}, {13, 6, 14}, {7, 13}, {13,
    7}, {8, 10}, {10, 8}, {9, 11}, {11, 9}, {12, 14}, {14, 12}},
 {{1, 2, 3}, {4, 5, 6}, {1, 4}, {4, 1}, {2, 5}, {5, 2}, {3, 6}, {6,
   3}},
 <|"MaxVertices" -> 300, "MaxEvents" -> 200|>]
```

<img src="/Documentation/Images/MaxVerticesEvolutionObject.png" width="753">

All possible keys in that association are:

* `"MaxEvents"`: limit the number of individual replacements (in the [`SetReplace`](../SetReplace*.md) function meaning).
* `"MaxGenerations"`: limit the number of generations (steps in [`SetReplaceAll`](../SetReplace*.md) meaning), same as specifying steps directly as a number in `WolframModel`.
* `"MaxVertices"`: limit the number of vertices in the *final* state only (the total count throughout evolution might be larger). This limit stops evolution if the next event, if applied, would put the state over the limit. Note once such an event is encountered, the evolution stops immediately even if other matches exist that would not put the vertex count over the limit.
* `"MaxVertexDegree"`: limit the number of final state edges in which any particular vertex is involved. Works in a similar way to `"MaxVertices"`.
* `"MaxEdges"`: limit the number of edges (set elements) in the final state. Works similarly to `"MaxVertices"`.

Any combination of these can be used, in which case the earliest triggered condition stops the evolution.

Note also that `"MaxGenerations"` works differently from the other limiters, as the matching algorithm would not even attempt to match edges with generations over the limit. Therefore unlike, i.e., `"MaxVertices"`, which would terminate the evolution immediately once the limit-violating event is attempted, `"MaxGenerations"` would keep "filling in" events for as long as possible until no further matches within allowed generations are possible.

It is also possible to set the step count to `Automatic`, in which case `WolframModel` tries to automatically pick a number of steps that showcases the evolution without taking too long. It stops the evolution sooner if the state grows quickly:

```wl
In[] := WolframModel[{{1, 2, 3}, {2, 4, 5}} -> {{5, 6, 1}, {6, 4, 2}, {4, 5,
    3}},
 {{1, 2, 3}, {2, 4, 5}, {4, 6, 7}}, Automatic]
```

<img src="/Documentation/Images/AutomaticStepsGrowing.png" width="491">

But evolves the rule much longer if it does not grow:

```wl
In[] := WolframModel[<|"PatternRules" -> {{a_, b_}} :> {{a + b, a - b}}|>,
 {{1, 1}}, Automatic]
```

<img src="/Documentation/Images/AutomaticStepsNotGrowing.png" width="565">

Currently, it's equivalent to `<|"MaxEvents" -> 5000, "MaxVertices" -> 200|>`, setting `TimeConstraint -> 5` (it still returns values for all properties even if terminated due to time constraint), and `"IncludePartialGenerations" -> False`, but it may be adjusted in future updates.

## Properties

- [All Edges throughout Evolution](Properties/AllEdgesThroughoutEvolution.md)
- [Causal Graphs](Properties/CausalGraphs.md)
- [Creator and Destroyer Events](Properties/CreatorAndDestroyerEvents.md)
- [Edge and Event Generations](Properties/EdgeAndEventGenerations.md)
- [Element Count Lists](Properties/ElementCountLists.md)
- [Event Counts](Properties/EventCounts.md)
- [Events](Properties/Events.md)
- [Events and States](Properties/EventsAndStates.md)
- [Expression Separations](Properties/ExpressionSeparations.md)
- [Final Element Counts](Properties/FinalElementCounts.md)
- [Generation Counts](Properties/GenerationCounts.md)
- [Plots of Events](Properties/PlotsOfEvents.md)
- [Plots of States](Properties/PlotsOfStates.md)
- [Rule Indices for Events](Properties/RuleIndicesForEvents.md)
- [Rules](Properties/Rules.md)
- [States](Properties/States.md)
- [States as Edge Indices](Properties/StatesAsEdgeIndices.md)
- [Termination Reason](Properties/TerminationReason.md)
- [Total Element Counts](Properties/TotalElementCounts.md)
- [Version](Properties/Version.md) 

## Options

- ["VertexNamingFunction"](Options/VertexNamingFunction.md)
- ["IncludePartialGenerations"](Options/IncludePartialGenerations.md)
- ["IncludeBoundaryEvents"](Options/IncludeBoundaryEvents.md)
- ["EventOrderingFunction"](Options/EventOrderingFunction.md)
- ["EventSelectionFunction"](Options/EventSelectionFunction.md)
- ["EventDeduplication"](Options/EventDeduplication.md)
- [Method](Options/Method.md)
- [Time Constraint](Options/TimeConstraint.md)
