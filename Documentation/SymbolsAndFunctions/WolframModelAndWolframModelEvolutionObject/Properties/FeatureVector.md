###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# FeatureVector

**`"FeatureVector"`** computes some features of
the [`WolframModel`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md)
evolution. For now, it only computes properties associated with the causal graph `g`:

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureVector"]
Out[] = {22, 42, 0, 2, 2, 2, 6, 6}
```

The list of properties is:

- [`VertexCount`](https://reference.wolfram.com/language/ref/VertexCount.html): The number of vertices in the causal
  graph. Related to
  the [total number of events](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/EventCounts.md)
- [`EdgeCount`](https://reference.wolfram.com/language/ref/EdgeCount.html): The number of edges in the causal graph.
  Related to
  the [total number of expressions](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/TotalElementCounts.md)
- [`VertexConnectivity`](https://reference.wolfram.com/language/ref/VertexConnectivity.html): The smallest number of
  vertices whose deletion from `g` disconnects `g`. This is computed on the undirected version of the causal graph.
- [`VertexDegree`](https://reference.wolfram.com/language/ref/VertexDegree.html) Quantiles: The quantiles 0, 0.25, 0.50,
  0.75, 1 of the vertex degrees distribution.

This property is useful for applying machine learning to Wolfram Models explorations.

## Example

```wl
inits = Partition[#, 2] & /@ Tuples[ConstantArray[Range[0, 3], 4]];

In[] := FeatureSpacePlot[#["FeatureVector"] -> #[
     "CausalGraph"] & /@ (WolframModel[{{x, y}, {x, z}} -> {{x,
         z}, {x, w}, {y, w}, {z, w}}, #, 6] &) /@ inits]
```

<img src="/Documentation/Images/FeatureVectorFeatureSpacePlot.png" width=478>
