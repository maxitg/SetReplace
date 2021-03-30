###### [Type System](README.md)

# Multihistory

**`Multihistory`** is a head used for [types](/Documentation/SymbolsAndFunctions/Types/README.md) representing an
evaluation history of a computational system.

For example, for
a [`MultisetSubstitutionSystem`](/Documentation/SymbolsAndFunctions/Systems/MultisetSubstitutionSystem.md),

```wl
In[] := GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}],
                             {},
                             None,
                             {"InputCount", "SortedInputExpressions", "UnsortedInputExpressions", "RuleIndex"},
                             {"MaxEvents" -> 10}] @ {1, 2, 3}
```

<img src="/Documentation/Images/MultisetMultihistory.png" width="472.2">

You will be able to use [`properties`]($SetReplaceProperties.md) to extract information about multihistories, but we
have not implemented any properties yet.
