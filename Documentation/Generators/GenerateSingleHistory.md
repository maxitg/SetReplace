# GenerateSingleHistory

**`GenerateSingleHistory`** generates single histories, which it achieves by setting
[`MaxDestroyerEvents`](MaxDestroyerEvents.md) to one. Note that for nondeterministic systems the history generated may
depend on the event order.

For example, for a [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md):

```wl
In[] := multihistory = GenerateSingleHistory[
  MultisetSubstitutionSystem[{a_, b_} :> {a + b, a - b, a * b}], {1, 2}, MaxEvents -> 10]
```

<img src="/Documentation/Images/MultisetMultihistory.png" width="472.2">

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] @ multihistory
```

<img src="/Documentation/Images/GenerateSingleHistoryExample.png" width="478.2">

Note that single histories are not necessarily single-path systems. Multiple rewriting events can be possible starting
from a given state. However, only one event can take any given token as an input, which ensures that all generated
events do not conflict with each other (i.e., there are no branchlike-separated events).
