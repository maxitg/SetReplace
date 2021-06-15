# Stopping Condition Parameters

Stopping condition controls when the evaluation should be terminated. Unlike the
[event selection parameters](EventSelectionParameters.md), the termination occurs immediately once one of these
conditions is reached, even if a further evaluation would be possible with a different
[event ordering](EventOrderingFunctions.md).

**`StoppingConditionParameters`** allows one to obtain the list of parameters available for a particular system:

```wl
In[] := StoppingConditionParameters[MultisetSubstitutionSystem]
Out[] = {"MaxEvents"}
```

They typically correspond to the values returned by the `TerminationReason` property. These values can be used as keys
for the corresponding arguments of [generators](README.md).

## MaxEvents

This is the most basic stopping condition. It stops the evaluation once the given number of events is reached
(regardless of causal dependencies between these events):

```wl
In[] := #["ExpressionsEventsGraph"] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}],
                         {},
                         None,
                         EventOrderingFunctions[MultisetSubstitutionSystem],
                         {"MaxEvents" -> 9}] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MaxEventsExample.png" width="478.2">

Compare to [`"MaxGeneration"`](EventSelectionParameters.md#maxgeneration) which controls the depth of the evaluation
instead.
