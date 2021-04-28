# MultisetSubstitutionSystem

States in the **`MultisetSubstitutionSystem`** are unordered multisets of tokens, which are arbitrary Wolfram Language
expressions. Events take submultisets of these and replace them with other submultisets.

The left-hand sides of rules are written as Wolfram Language patterns. However, the first level of these patterns can be
matched in any order, so `{n__Integer, s_String}` and `{s_String, n__Integer}` are equivalent, for example, aside from
their effect on the [event ordering](/Documentation/Generators/EventOrderingFunctions.md).

The right-hand sides determine what these patterns should be replaced with (similar to how
[`Replace`](https://reference.wolfram.com/language/ref/Replace.html) works).

For example, to make a system that adds pairs of numbers:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         {"MaxDestroyerEvents" -> 1, "MaxEventInputs" -> 2},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemExample.png" width="444.6">

Arbitrary Wolfram Language patterns are supported including
[conditions](https://reference.wolfram.com/language/ref/Condition.html) (`{a_ /; a > 0, b_}` or
`{a_, b_} /; a + b == 3`) and [sequences](https://reference.wolfram.com/language/ref/BlankSequence.html) that match
multiple tokens at once in any order (`{a__}`). Any code is supported on the right-hand side as long as it always
generates a list. For example:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[
      MultisetSubstitutionSystem[{a__} /; OrderedQ[{a}] && PrimeQ[Plus[a]] :> First /@ FactorInteger[Plus[a]]],
      {"MinEventInputs" -> 2, "MaxEventInputs" -> 4},
      None,
      EventOrderingFunctions[MultisetSubstitutionSystem],
      {}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MultisetSubstitutionSystemConditionsAndSequences.png" width="478.2">

`MultisetSubstitutionSystem` supports
[`"MaxGeneration"`](/Documentation/Generators/EventSelectionParameters.md#maxgeneration),
[`"MaxDestroyerEvents"`](/Documentation/Generators/EventSelectionParameters.md#maxdestroyerevents),
[`"MinEventInputs"` and `"MaxEventInputs"`](/Documentation/Generators/EventSelectionParameters.md#mineventinputs-and-maxeventinputs)
for [event selection](/Documentation/Generators/EventSelectionParameters.md). It supports
[`"MaxEvents"`](/Documentation/Generators/StoppingConditionParameters.md#maxevents) as a
[stopping condition](/Documentation/Generators/StoppingConditionParameters.md). Only a single
[event ordering](/Documentation/Generators/EventOrderingFunctions.md)
`{"InputCount", "SortedInputTokenIndices", "InputTokenIndices", "RuleIndex", "InstantiationIndex"}` is implemented at
the moment.

`MultisetSubstitutionSystem` produces
[`{MultisetSubstitutionSystem, 0}`](/Documentation/Types/Multihistory/MultisetSubstitutionSystem0.md) objects.

## Current Limitations

* The current version does no introspection of the rules, so it is slow since it has to enumerate all subsets of tokens
in the multihistory for every new event.
[`"MaxEventInputs"`](/Documentation/Generators/EventSelectionParameters.md#mineventinputs-and-maxeventinputs) can be
used as a workaround.
* Token deduplication is not implemented. The only value supported is
[`None`](https://reference.wolfram.com/language/ref/None.html).
* Only `{"InputCount", "SortedInputTokenIndices", "InputTokenIndices", "RuleIndex", "InstantiationIndex"}` is
implemented for event ordering.