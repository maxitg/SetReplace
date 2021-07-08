# Multihistory

**`Multihistory`** is a head used for [types](README.md) representing an evaluation history of a
[computational system](/Documentation/Systems/README.md).

For example, for a [`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md),

```wl
In[] := GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], {1, 2, 3}, MaxEvents -> 10]
```

<img src="/Documentation/Images/MultisetMultihistory.png" width="472.2">

You will be able to use [`properties`](/Documentation/Properties/README.md) to extract information about multihistories,
but we have not implemented any properties yet.

* [`{AtomicStateSystem, 0}`](AtomicStateSystem0.md)
* [`{MultisetSubstitutionSystem, 0}`](MultisetSubstitutionSystem0.md)
