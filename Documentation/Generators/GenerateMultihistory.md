###### [Generators](README.md)

# GenerateMultihistory

**`GenerateMultihistory`** is the most verbose and the most configurable generator. It can generate both single
histories, full multihistories, as well as partial ones. It, however, requires one to specify all groups of parameters
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
