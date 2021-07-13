# Multihistory

**`Multihistory`** is a head used for [types](README.md) representing an evaluation history of a
[computational system](/Documentation/Systems/README.md).

For example, for a [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md),

```wl
In[] := GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], MaxEvents -> 10] @ {1, 2, 3}
```

<img src="/Documentation/Images/MultisetMultihistory.png" width="426.6">

You will be able to use [`properties`](/Documentation/Properties/README.md) to extract information about multihistories,
but we have not implemented any properties yet.

* [`AtomicStateSystem`](AtomicStateSystem0.md)
* [`MultisetSubstitutionSystem`](MultisetSubstitutionSystem0.md)
