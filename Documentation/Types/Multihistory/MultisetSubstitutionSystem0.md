# MultisetSubstitutionSystem Multihistory

[**`MultisetSubstitutionSystem`**](/Documentation/Systems/MultisetSubstitutionSystem.md) [`Multihistory`](README.md)
object is returned by [generators](/Documentation/Generators/README.md) of the
[`MultisetSubstitutionSystem`](/Documentation/Systems/MultisetSubstitutionSystem.md):

```wl
In[] := GenerateMultihistory[MultisetSubstitutionSystem[{a_, b_} :> {a + b}], MaxEvents -> 10] @ {1, 2, 3}
```

<img src="/Documentation/Images/MultisetMultihistory.png" width="426.6">

It is implemented as an [`Association`](https://reference.wolfram.com/language/guide/Associations.html) of
[data structures](https://reference.wolfram.com/language/ref/DataStructure.html) containing information about the rules,
termination reason, contents of expressions, rule indices used for each event, event inputs and outputs, generations,
separations of expressions and other values used for optimization.

There are no properties implemented for it yet, however, it can be
[converted](/Documentation/TypeSystem/SetReplaceTypeConvert.md) to a
[WolframModelEvolutionObject](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md)
for backwards compatibility.
