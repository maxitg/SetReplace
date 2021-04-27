###### [Generators](README.md)

# StoppingConditionParameters

**`StoppingConditionParameters`** allows one to obtain the list of parameters that determine when the evaluation of a
[computational system](/Documentation/Systems/README.md) should be terminated:

```wl
In[] := StoppingConditionParameters[MultisetSubstitutionSystem]
Out[] = {"MaxEvents"}
```

They typically correspond to the values returned by the `TerminationReason` property. These values can be used as keys
for the corresponding arguments of [generators](README.md).

## Stopping Conditions

Stopping conditions control when the evaluation should be terminated. Unlike the
[event selection parameters](EventSelectionParameters.md), the termination will occur immediately after one of these
conditions is reached, even if further evaluation would be possible given a different
[event ordering](EventOrderingFunctions.md).

### MaxEvents

This is the most basic stopping condition. It stops the evaluation once the given number of events is reached
(regardless of causal dependencies between these events):

```wl
In[] := #["ExpressionsEventsGraph"] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         {"MaxEventInputs" -> 2},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {"MaxEvents" -> 9}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MaxEventsExample.png" width="478.2">

Compare to [`"MaxGeneration"`](EventSelectionParameters.md#maxgeneration) which controls the depth of the evaluation
instead.
