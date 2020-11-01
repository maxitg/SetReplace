###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# FeaturesExtractor

**`"FeaturesExtractor"`** computes on the fly some features about the `WolframModel`. For now it only computes properties associated to the causal graph `g`.

The list of properties are:
- VertexCount: number of vertexes
- EdgeCount: number of edges
- VertexConnectivity: the smallest number of vertices whose deletion from `g` disconnects `g`
- VertexDegreesQuantiles: The quantiles 0, 0.25, 0.50, 0.75, 1 of the vertex degrees distribution


Example usage:
```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, 
     w}}, {{0, 0}, {0, 0}}, 5]["FeaturesExtractor"]
Out[] = {22, 42, 0, 2, 2, 2, 6, 6}
```

This module is useful for applying machine-learning to Wolfram Models explorations.
