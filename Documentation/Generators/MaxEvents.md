# MaxEvents

`MaxEvents` is the most basic stopping condition. It stops the evaluation once the given number of events is reached
(regardless of causal dependencies between these events):

```wl
In[] := #["ExpressionsEventsGraph"] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} /; a < b :> {a + b}], MaxEvents -> 9] @ {1, 2, 3, 4}
```

<img src="/Documentation/Images/MaxEventsExample.png"
     width="478.2"
     alt="Out[] = ... token-event graph with 9 events ...">

Compare to [`MaxGeneration`](MaxGeneration.md), which controls the depth of the evaluation instead.
