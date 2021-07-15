# GenerateSingleHistory

**`GenerateSingleHistory`** generates single histories, which it achieves by setting
[`MaxDestroyerEvents`](MaxDestroyerEvents.md) to one. Note that for nondeterministic systems, the history generated may
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

Note that there is a distinction between single-history and single-path systems. Single-path systems are defined as ones
where there is only one event possible from every state. A Turing machine would be an example of a single-path system.
On the other hand, single-history systems allow multiple events from a single state, but all these events must be
consistent, i.e., take non-overlapping inputs. Neither single-path nor single-history systems have branchlike-separated
events.
