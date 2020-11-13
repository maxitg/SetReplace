###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# FeatureAssociation

**`"FeatureAssociation"`** computes some features of the [`WolframModel`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md) evolution and returns an association whose keys describe each feature computed. For now, it computes properties associated with the [`CausalGraph`](LINK) and with the graph version of the [`FinalState`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/States.md) as given by [`HypergraphToGraph`](/Documentation/SymbolsAndFunctions/UtilityFunctions/HypergraphToGraph.md) using the [`StructurePreserving`] transformation:

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureAssociation"]
Out[] = <| "CausalGraphVertexCount" -> 22, "CausalGraphEdgeCount" -> 42, 
 "CausalGraphVertexConnectivity" -> 1, 
 "CausalGraphVertexDegreesQuantiles" -> {2, 2, 2, 6, 6}, 
 "StructurePreservingFinalStateVertexCount" -> 115, 
 "StructurePreservingFinalStateEdgeCount" -> 138, 
 "StructurePreservingFinalStateVertexConnectivity" -> 2, 
 "StructurePreservingFinalStateVertexDegreesQuantiles" -> {2, 2, 2, 2,8} |>
```

The list of properties computed for each graph `g` is:
- [`VertexCount`](https://reference.wolfram.com/language/ref/VertexCount.html): The number of vertices in the causal graph. Related to the [total number of events](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/EventCounts.md)
- [`EdgeCount`](https://reference.wolfram.com/language/ref/EdgeCount.html): The number of edges in the causal graph. Related to the [total number of expressions](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/TotalElementCounts.md)
- [`VertexConnectivity`](https://reference.wolfram.com/language/ref/VertexConnectivity.html): The smallest number of vertices whose deletion from `g` disconnects `g`. This is computed on the undirected version of the given graph.
- [`VertexDegree`](https://reference.wolfram.com/language/ref/VertexDegree.html) Quantiles: The quantiles 0, 0.25, 0.50, 0.75, 1 of the vertex degrees distribution.

This property is useful for applying machine learning to Wolfram Models explorations.

## Example

```wl
inits = Partition[#, 2] & /@ Tuples[ConstantArray[Range[0, 3], 4]];

In[] := FeatureSpacePlot[#["FeatureAssociation"] -> #[
     "CausalGraph"] & /@ (WolframModel[{{x, y}, {x, z}} -> {{x,
         z}, {x, w}, {y, w}, {z, w}}, #, 6] &) /@ inits]
```

<img src="/Documentation/Images/FeatureAssociationFeatureSpacePlot.png" width=720>

For [`MultiwaySystems`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/MultiwayQ.md) it only computes property associated with the [`CausalGraph`]

## Example

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{1, 1}, {1, 0}, {1, 1}}, 3, "EventSelectionFunction" -> "MultiwaySpacelike"]["FeatureAssociation"]
Out[] = <| "CausalGraphVertexCount" -> 4054, "CausalGraphEdgeCount" -> 7824, \
"CausalGraphVertexConnectivity" -> 0, \
"CausalGraphVertexDegreesQuantiles" -> {1, 2, 2, 2, 260} |>
```
