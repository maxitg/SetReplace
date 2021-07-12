# MaxEvents

`MaxEvents` is the most basic stopping condition. It stops the evaluation once the given number of events is reached
(regardless of causal dependencies between these events):

```wl
In[] := #["ExpressionsEventsGraph"] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}], {1, 2, 3, 4}, MaxEvents -> 9]
```

<img src="/Documentation/Images/MaxEventsExample.png" width="478.2">

Compare to [`MaxGeneration`](MaxGeneration.md), which controls the depth of the evaluation instead.
