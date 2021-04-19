###### [Generators](README.md)

# EventOrderingFunctions

**`EventOrderingFunctions`** allows one to obtain the list of event ordering functions that can be used with a
[computational system](/Documentation/Systems/README.md):

```wl
In[] := EventOrderingFunctions[MultisetSubstitutionSystem]
Out[] = {"InputCount", "SortedInputTokenIndices", "InputTokenIndices", "RuleIndex", "InstantiationIndex"}
```

The individual values returned correspond to partial sorting criteria supported by the system. They are used in the
order they are passed to [generators](README.md). The first criterion is applied first. If ambiguities are remaining,
the second criterion is used, etc.

Note that in some cases, systems can impose additional restrictions on which combinations of ordering functions can be
used.

## Ordering Functions

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

<img src="/Documentation/Images/SameStateMultipleMatches.png" width="478.2">

Event ordering functions control the order in which these matches will be instantiated.

The importance of that order depends on the system, the rules, and the evaluation parameters. For example, in the
example above, full multihistory is generated up to generation 1. In this case, the same multihistory is generated
regardless of the event ordering, so the event ordering does not matter all that much. For this reason, there is no
argument for the event ordering in `GenerateFullMultihistory` (not yet implemented).

However, if we evaluate a single history instead, we can get different histories for different orders (different orders
are made here by rearranging the order of the init as
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) only supports a single ordering
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
histories are different, the final state will always be the same, assuming the system is evolved to completion.

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

For this reason, generators such as `GenerateSingleHistory` (not yet implemented) require specification of the ordering
function as one of the arguments, as, without it, the evaluation will be ambiguous.

### InputCount

As few tokens as possible will be matched. This is particularly useful for systems such as
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) where a single rule can match
different token counts.

For example, the [multiset](/Documentation/Systems/MultisetSubstitutionSystem.md) pattern `{a___}` will match `{6, 7}`
before `{1, 2, 3}` with this ordering function.

### SortedInputTokenIndices

As events are instantiated according to the ordering function, each token in a
[`Multihistory`](/Documentation/Types/Multihistory/README.md) has an index corresponding to when that token was first
created.

`"SortedInputTokenIndices"` ordering function sorts the tokens in a particular match by index and then selects the
lexicographically smallest result. This corresponds to effectively
`{"MinInputTokenIndex", "SecondMinInputTokenIndex", ...}`. If one of the sorted index lists is a prefix of another, they
are considered equal by this ordering function. [`"InputCount"`](#inputcount) will need to be used to resolve the
ambiguity.

In other words, this ordering function attempts to match the oldest token possible. And if multiple matches remain after
that, it attempts to match the oldest of the remaining tokens, etc.

For example, the [multiset](/Documentation/Systems/MultisetSubstitutionSystem.md) pattern `{a_, b_, c_}` will match
tokens with indices `{7, 1, 6}` before `{3, 2}` (since `1 < 2`), and `{4, 6, 2}` before `{5, 2, 6}` (since `2 == 2` and
`4 < 5`).

### InputTokenIndices

This function is similar to [`"SortedInputTokenIndices"`](#sortedinputtokenindices), except tokens are not sorted before
being lexicographically compared. This corresponds to greedily matching the first rule input to a token with the
smallest index, then following with the second input, etc.

For example, the [multiset](/Documentation/Systems/MultisetSubstitutionSystem.md) pattern `{a_, b_, c_}` will match
tokens with indices `{3, 2}` before `{7, 1, 6}` (since `3 < 7`), and `{3, 1, 2}` before `{3, 4}` (since `3 == 3` and
`1 < 4`). Similar to [`"SortedInputTokenIndices"`](#sortedinputtokenindices), `{1, 4}` and `{1, 4, 2}` will be consider
equal by this function, and will be passed to the next one.

### RuleIndex

This function attempts to use a rule with the smallest index for multi-rule systems. Only if there are no matches for
the first rule, the second rule will be attempted, etc. It does not affect single-rule systems.

### InstantiationIndex

In some cases, even the same sequence of input tokens can lead to different outputs. For example, the
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md) pattern `{a__, b__}` can match
tokens `{1, 2, 3}` either as `{a} -> {1}`, `{b} -> {2, 3}` or as `{a} -> {1, 2}`, `{b} -> {3}`, yielding different
outputs in a rule such as `{a__, b__} :> {{a}, {b}}`.

To resolve this ambiguity, `"InstantiationIndex"` ordering function can be used. The specific order of instantiations
depends on the system. In [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md), the
order is the same as in [`ReplaceList`](https://reference.wolfram.com/language/ref/ReplaceList.html).

If used in front of all other ordering functions, it attempts to only do a single instantiation for each sequence of
tokens unless there are no other matches available.
