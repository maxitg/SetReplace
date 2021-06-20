# {HypergraphSubstitutionSystem, 0}

**`{HypergraphSubstitutionSystem, 0}`** is a [`Multihistory`](README.md) type currently returned by
[generators](/Documentation/Generators/README.md) of the
[`HypergraphSubstitutionSystem`](/Documentation/Systems/HypergraphSubstitutionSystem.md):

```wl
In[] := multi = GenerateMultihistory[HypergraphSubstitutionSystem[{{a_, b_}, {a_, c_}} :> {{b, c}}],
                                     {"MaxDestroyerEvents" -> 2},
                                     None,
                                     {"ReverseSortedInputTokenIndices", "InputTokenIndices", "RuleIndex"},
                                     {}] @ {{1, 2}, {1, 3}}
```

<img src="/Documentation/Images/HypergraphMultihistory.png" width="607.8">

It uses the hypergraph related C++ code found in the [libSetReplace](/libSetReplace/), same as what [WolframModel](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md) uses when the option
[Method -> "LowLevel"](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Options/Method.md)
is called.

The information about the multihistory is not entirely stored in the generated object. Instead, a handle to the C++
hypergraph object is kept inside (see
[Managed Library Expressions](https://reference.wolfram.com/language/LibraryLink/tutorial/InteractionWithWolframLanguage#353220453)):

```wl
In[] := multi[[2]]

Out[] = <|"Rules" -> {{a_, b_}, {a_, c_}} :> {{b, c}},
          "GlobalAtoms" -> {Hold[1], Hold[2], Hold[3]},
          "ObjectHandle" -> HypergraphSubstitutionSystemHandle[1]|>
```

No properties are implemented yet. However, the object can be
[converted](/Documentation/TypeSystem/SetReplaceTypeConvert.md) to a
[WolframModelEvolutionObject](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md):

```wl
In[] := multi //
          SetReplaceTypeConvert[{WolframModelEvolutionObject, 2}] //
            #["ExpressionsEventsGraph", VertexLabels -> Automatic] &
```

<img src="/Documentation/Images/HypergraphToWolframModelEvolutionObject1.png" width="385.8">
