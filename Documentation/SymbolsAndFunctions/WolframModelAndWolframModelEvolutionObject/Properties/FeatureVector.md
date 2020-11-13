###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# FeatureVector

**`"FeatureVector"`** returns the values of the features of the [`WolframModel`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md) evolution as computed by [`FeatureAssociation`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/FeatureAssociation.md).

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureVector"]
Out[] = {22, 42, 1, 2, 2, 2, 6, 6, 115, 138, 2, 2, 2, 2, 2, 8}
```

For the list of properties see [`FeatureAssociation`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/FeatureAssociation.md)

## Example

```wl
inits = Partition[#, 2] & /@ Tuples[ConstantArray[Range[0, 3], 4]];

In[] := FeatureSpacePlot[#["FeatureVector"] -> #[
     "CausalGraph"] & /@ (WolframModel[{{x, y}, {x, z}} -> {{x,
         z}, {x, w}, {y, w}, {z, w}}, #, 6] &) /@ inits]
```

<img src="/Documentation/Images/FeatureVectorFeatureSpacePlot.png" width=478>
