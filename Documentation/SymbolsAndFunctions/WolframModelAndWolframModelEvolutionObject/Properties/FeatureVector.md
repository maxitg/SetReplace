###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Feature Vector

**`"FeatureVector"`** returns the values of the features of the [`WolframModel`](/Documentation/SymbolsAndFunctions/
WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md) evolution as computed by
[`"FeatureAssociation"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/
FeatureAssociation.md).

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureVector"]
Out[] = {22, 42, 1, 2, 2, 2, 6, 6, 115, 138, 2, 2, 2, 2, 2, 8}
```

For the list of features see [`FeatureAssociation`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/FeatureAssociation.md).

This property is useful for applying machine learning to Wolfram Models explorations.

## Example

```wl
In[] := BlockRandom[
  FeatureSpacePlot[#["FeatureVector"] -> Image[#["FinalStatePlot"], ImageSize -> Tiny] & /@
    (WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, #, 6] &) /@
      Table[RandomHypergraph[{3, 2}, 2], 10], LabelingFunction -> Callout], RandomSeeding -> 2
]
```

<img src="/Documentation/Images/FeatureVectorFeatureSpacePlot.png" width="815.4">
