# AtomicStateSystem Multihistory

[**`AtomicStateSystem`**](/Documentation/Systems/AtomicStateSystem.md) [`Multihistory`](README.md) object is returned by
[generators](/Documentation/Generators/README.md) of the
[`AtomicStateSystem`](/Documentation/Systems/AtomicStateSystem.md):

```wl
In[] := GenerateMultihistory[AtomicStateSystem[a_ :> a + 1], MaxEvents -> 10][0]
```

<img src="/Documentation/Images/AtomicStateMultihistory.png"
     width="378.6"
     alt="Out[] = Multihistory[... AtomicStateSystem v0 ...]">

Internally, [`AtomicStateSystem`](/Documentation/Systems/AtomicStateSystem.md) is implemented by running a special case
of the [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md). The object contains a
[`MultisetSubstitutionSystem` multihistory](MultisetSubstitutionSystem0.md) and can be converted to it.
