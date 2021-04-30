# AtomicStateSystem

**`AtomicStateSystem`** is a simple system where states consist of single tokens. The rules consist of patterns on the
left that can match these states, and the arbitrary code on the right that creates a new state:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @
    GenerateMultihistory[AtomicStateSystem[{n_ :> n + 1, n_ :> n - 1}],
                         {"MaxGeneration" -> 4},
                         None,
                         EventOrderingFunctions[AtomicStateSystem],
                         {}] @ 0
```

<img src="/Documentation/Images/AtomicStateSystemExample.png" width="858.6">

Note that spacelike separation is not possible in the `AtomicStateSystem`. As a result, since events cannot currently
produce branchlike-separated outputs, events in this system can only generate a single state. Branching can only occur
due to multiple rules.
