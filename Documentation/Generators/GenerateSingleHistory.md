# GenerateSingleHistory

**`GenerateSingleHistory`** generates single histories, which it achieves by setting
[`MaxDestroyerEvents`](MaxDestroyerEvents.md) to one. Note that for nondeterministic systems, the history generated may
depend on the event order.

For example, for a [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md):

```wl
In[] := multihistory = GenerateSingleHistory[
  MultisetSubstitutionSystem[{a_, b_} :> {a + b, a - b, a * b}], MaxEvents -> 10] @ {1, 2}
```

<img src="/Documentation/Images/MultisetMultihistory.png"
     width="426.6"
     alt="Out[] = Multihistory[... MultisetSubstitutionSystem v0 ...]">

```wl
In[] := #["ExpressionsEventsGraph", VertexLabels -> Placed[Automatic, After]] & @
  SetReplaceTypeConvert[WolframModelEvolutionObject] @ multihistory
```

<img src="/Documentation/Images/GenerateSingleHistoryExample.png"
     width="478.2"
     alt="Out[] = Graph[...
       token-event graph where all tokens have out degrees less or equal than 1:
       {1, 2 (* init *)} -> {3, -1, 2 (* gen 1 *)},
       {3, -1} -> {2 (* gen 2 *), 4 (* gen 2 *), -3},
       {2 (* gen 1 *), 2 (* gen 2 *)} -> {4 (* gen 3 sum *), 0, 4 (* gen 3 product *)},
       <<7>>
     ...]">

Note that there is a distinction between single-history and single-path systems. Single-path systems are defined as ones
where there is only one event possible from every state. A Turing machine would be an example of a single-path system.
On the other hand, single-history systems allow multiple events from a single state, but all these events must be
consistent, i.e., take non-overlapping inputs. Neither single-path nor single-history systems have branchlike-separated
events.
