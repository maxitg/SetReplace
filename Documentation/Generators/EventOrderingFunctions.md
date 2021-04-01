###### [Generators](README.md)

# EventOrderingFunctions

**`EventOrderingFunctions`** allows one to obtain the list of event ordering functions that can be used with a
[computational system](/Documentation/Systems/README.md):

```wl
In[] := EventOrderingFunctions[MultisetSubstitutionSystem]
Out[] = {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"}
```

The individual values returned correspond to partial sorting criteria supported by the system. They are used in the
order they are passed to [generators](README.md). The first criterion is applied first. If there are ambiguities
remaining, the second criterion is used, etc.

Note that in some cases systems can impose additional restrictions on which combinations of ordering functions can be
used.

## Guide to Ordering Functions

Given a state of a computational system, multiple matches are sometimes possible simultaneously. For example, in the
system below one can match any pair of numbers, many of which overlapping:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         {"MaxGeneration" -> 1, "MaxEventInputs" -> 2},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @
       {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultipleMatches.png" width="444.6">

Event ordering functions control the order in which these matches will be instantiated.

The importance of that order depends on the system, the rules, and the parameters of the evaluation.

For example, in the example below, full multihistory is generated up to generation 1. In this case, the same
multihistory is generated regardless of the event ordering, so, the event ordering does not matter all that much. For
this reason, there is no argument for the event ordering `GenerateFullMultihistory`.

However, if we evaluate a single history instead, we can get different histories for different orders (different orders
are made here by rearranging the order of the init as `MultisetSubstitutionSystem` only supports a single ordering
function at the moment):

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & /@
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] /@
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         {"MaxDestroyerEvents" -> 1},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] /@
      {{1, 2, 3, 4}, {1, 3, 2, 4}}
```

<img src="/Documentation/Images/DifferentOrdersDifferentHistories.png" width="484.2">

This system, however, is [confluent](https://en.wikipedia.org/wiki/Confluence_(abstract_rewriting)), so, even if the
histories are different, the final state will always be the same assuming the system is evolved to completion.

However, it is not the case for all systems. For example, see what happens if we change `+` to `-`:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & /@
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] /@
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a - b}],
                         {"MaxDestroyerEvents" -> 1},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] /@
      {{1, 2, 3, 5}, {1, 5, 2, 3}}
```

<img src="/Documentation/Images/DifferentOrdersDifferentFinalStates.png" width="484.2">

For this reason, generators such as `GenerateSingleHistory` require specification of the ordering function as one of the
arguments, as, without it, the evaluation will be ambiguous.

## List of Ordering Functions

### InputCount

As few tokens as possible will be matched. This is particularly useful for systems such as
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) where a single rule can match
different token counts.

For example, the rule `{a___} :> {Plus[a]}` will match `{6, 7}` before `{1, 2, 3}` with this ordering function.

### SortedInputExpressions
