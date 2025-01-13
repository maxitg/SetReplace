# AtomicStateSystem

**`AtomicStateSystem`** is a simple system where states consist of single tokens. The rules consist of patterns on the
left that can match these states, and the arbitrary code on the right that creates a new state:

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @
    GenerateMultihistory[AtomicStateSystem[{n_ :> n + 1, n_ :> n - 1}], MaxGeneration -> 4][0]
```

<img src="/Documentation/Images/AtomicStateSystemExample.png"
     width="858.6"
     alt="Out[] = ... 0 -> Rule 1 -> 1, 0 -> Rule 2 -> -1, 1 -> Rule 1 -> 2, ..., -3 -> Rule 2 -> -4 ...">

Note that spacelike separation is not possible in the `AtomicStateSystem`. As a result, branching due to overlaps of
different subsets of input tokens cannot occur. And, since events cannot produce branchlike-separated outputs and there
is currently no way to assign multiple outputs to a single match of a left-hand side of a rule, branching can only occur
due to multiple rules.
