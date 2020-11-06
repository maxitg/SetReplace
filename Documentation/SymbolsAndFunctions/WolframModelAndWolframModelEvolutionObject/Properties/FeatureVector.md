###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# FeatureVector

**`"FeatureVector"`** computes some features of the [`WolframModel`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md) evolution. For now, it only computes properties associated with the causal graph `g`:

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureVector"]
Out[] = {22, 42, 0, 2, 2, 2, 6, 6}
```

The list of properties is:
- [`EventsCount`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/EventCounts.md): Also equal to the number of vertex in the causal graph.
- [`ExpressionsCountTotal`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/TotalElementCounts.md): the total number of expressions (except for expressions in the initial and final states). Equivalent to the number of edges in the causal graph.
- [`VertexConnectivity`](https://reference.wolfram.com/language/ref/VertexConnectivity.html): The smallest number of vertices whose deletion from `g` disconnects `g`. This is computed on the undirected version of the causal graph.
- [`VertexDegrees`](https://reference.wolfram.com/language/ref/VertexDegree.html) Quantiles: The quantiles 0, 0.25, 0.50, 0.75, 1 of the [vertices degrees](https://reference.wolfram.com/language/ref/VertexDegree.html) distribution.

This property is useful for applying machine learning to Wolfram Models explorations.

## Example

```wl
inits = Partition[#, 2] & /@ Tuples[ConstantArray[Range[0, 3], 4]];

In[] := FeatureSpacePlot[#["FeatureVector"] -> #[
     "CausalGraph"] & /@ (WolframModel[{{x, y}, {x, z}} -> {{x,
         z}, {x, w}, {y, w}, {z, w}}, #, 6] &) /@ inits]
```

<img src="/Documentation/Images/FeatureVector-FeatureSpacePlot.png" width=478>
