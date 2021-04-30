# {AtomicStateSystem, 0}

**`{AtomicStateSystem, 0}`** is a [`Multihistory`](README.md) type currently returned by
[generators](/Documentation/Generators/README.md) of the
[`AtomicStateSystem`](/Documentation/Systems/AtomicStateSystem.md):

```wl
In[] := GenerateMultihistory[
  AtomicStateSystem[a_ :> a + 1], {}, None, EventOrderingFunctions[AtomicStateSystem], {"MaxEvents" -> 10}] @ 0
```

<img src="/Documentation/Images/AtomicStateMultihistory.png" width="424.2">

Internally, `AtomicStateSystem` is implemented by running a special case of the
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md), and its multihistory contains a
corresponding [`{MultisetSubstitutionSystem, 0}`](MultisetSubstitutionSystem0.md), and it can be converted to it.
