###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Feature Association

**`"FeatureAssociation"`** computes some features of
the [`WolframModel`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md)
evolution and returns
an [`Association`](https://reference.wolfram.com/language/ref/Association.html) whose keys describe each feature
computed.
For now, it computes properties associated with these feature groups:

- [`"CausalGraph"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/CausalGraphs.md)
- `"StructurePreservingFinalStateGraph"`: The [`Graph`](https://reference.wolfram.com/language/ref/Graph.html)
version of
the [`"FinalState"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/States.md)
as given by [`HypergraphToGraph`](/Documentation/SymbolsAndFunctions/UtilityFunctions/HypergraphToGraph.md) using the
`"StructurePreserving"` transformation

```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureAssociation"]
Out[] = <|
 "CausalGraphVertexCount" -> 22,
 "CausalGraphEdgeCount" -> 42,
 "CausalGraphVertexConnectivity" -> 1,
 "CausalGraphVertexDegreesQuantiles" -> {2, 2, 2, 6, 6},
 "StructurePreservingFinalStateGraphVertexCount" -> 115,
 "StructurePreservingFinalStateGraphEdgeCount" -> 138,
 "StructurePreservingFinalStateGraphVertexConnectivity" -> 2,
 "StructurePreservingFinalStateGraphVertexDegreesQuantiles" -> {2, 2, 2, 2, 8}|>
```

The list of features computed for each graph `g` in a feature group is:

- [`VertexCount`](https://reference.wolfram.com/language/ref/VertexCount.html): The number of vertices in the graph.
- [`EdgeCount`](https://reference.wolfram.com/language/ref/EdgeCount.html): The number of edges in the graph.
- [`VertexConnectivity`](https://reference.wolfram.com/language/ref/VertexConnectivity.html): The smallest number of
vertices whose deletion from `g` disconnects `g`. This is computed on the undirected version of the given graph.
- [`VertexDegree`](https://reference.wolfram.com/language/ref/VertexDegree.html) Quantiles: The quantiles 0, 0.25, 0.50,
0.75, 1 of the vertex degrees distribution.

This property is useful for applying machine learning to Wolfram Models explorations:

```wl
In[] := BlockRandom[
  FeatureSpacePlot[#["FeatureAssociation"] -> Image[#["FinalStatePlot"], ImageSize -> Tiny] & /@
    (WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, #, 6] &) /@
      Table[RandomHypergraph[{3, 2}, 2], 10], LabelingFunction -> Callout], RandomSeeding -> 3
]
```

<img src="/Documentation/Images/FeatureAssociationFeatureSpacePlot.png" width="684.6">

For [Multiway Systems](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/MultiwayQ.md)
it only computes features associated with
the [causal graph](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/CausalGraphs.md),
returning `Missing["NotExistent", {"MultiwaySystem", "FinalState"}]` for features related to
`"StructurePreservingFinalStateGraph"`, as there is
no [`"FinalState"`](/Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/States.md)
in a Multiway System:

```wl
In[] := WolframModel[
  {{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}},
  {{1, 1}, {1, 0}, {1, 1}},
  3,
  "EventSelectionFunction" -> "MultiwaySpacelike"]["FeatureAssociation"]
Out[] = <|
  "CausalGraphVertexCount" -> 4054,
  "CausalGraphEdgeCount" -> 7824,
  "CausalGraphVertexConnectivity" -> 0,
  "CausalGraphVertexDegreesQuantiles" -> {1, 2, 2, 2, 260},
  "StructurePreservingFinalStateGraphVertexCount" -> Missing["NotExistent", {"MultiwaySystem", "FinalState"}],
  "StructurePreservingFinalStateGraphEdgeCount" -> Missing["NotExistent", {"MultiwaySystem", "FinalState"}],
  "StructurePreservingFinalStateGraphVertexConnectivity" -> Missing["NotExistent", {"MultiwaySystem", "FinalState"}],
  "StructurePreservingFinalStateGraphVertexDegreesQuantiles" -> {
    Missing["NotExistent", {"MultiwaySystem", "FinalState"}],
    Missing["NotExistent", {"MultiwaySystem", "FinalState"}],
    Missing["NotExistent", {"MultiwaySystem", "FinalState"}],
    Missing["NotExistent", {"MultiwaySystem", "FinalState"}],
    Missing["NotExistent", {"MultiwaySystem", "FinalState"}]}|>
```
