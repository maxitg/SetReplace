# GenerateMultihistory

**`GenerateMultihistory`** is the most verbose and configurable generator. It can create both single histories, full
multihistories, as well as partial ones. It, however, requires one to specify all groups of parameters
([system](/Documentation/Systems/README.md), [event selection](EventSelectionParameters.md), deduplication,
[event ordering](EventOrderingFunctions.md) and [stopping conditions](StoppingConditionParameters.md)), nothing is
implied automatically:

```wl
GenerateMultihistory[
  system, eventSelectionSpec, tokenDeduplicationSpec, eventOrderingSpec, stoppingConditionSpec] @ init
```

For example, for a [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md):

```wl
In[] := multihistory = GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}],
                                            {"MaxDestroyerEvents" -> 3},
                                            None,
                                            EventOrderingFunctions[MultisetSubstitutionSystem],
                                            {"MaxEvents" -> 10}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetMultihistory.png" width="472.2">

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @ multihistory
```

<img src="/Documentation/Images/GenerateMultihistoryExample.png" width="478.2">

Everything that can be generated with more specialized `GenerateSingleHistory` and `GenerateFullMultihistory` can be
reproduced with `GenerateMultihistory` as well. This can be done by setting `"MaxDestroyerEvents" -> 1` to emulate
`GenerateSingleHistory` and setting `"MaxDestroyerEvents" -> Infinity` and leaving the
[stopping condition](StoppingConditionParameters.md) empty to emulate `GenerateFullMultihistory`.

However, by setting `"MaxDestroyerEvents"` to finite values larger than 1, one can generate multihistories not possible
with other generators.
