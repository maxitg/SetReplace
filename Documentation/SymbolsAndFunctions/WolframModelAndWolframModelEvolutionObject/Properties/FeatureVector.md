###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# FeatureVector

**`"FeatureVector"`** computes some features of the [`WolframModel`](Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/WolframModelAndWolframModelEvolutionObject.md) evolution. For now, it only computes properties associated with the causal graph `g`:

Example usage:
```wl
In[] := WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, w}}, {{0, 0}, {0, 0}}, 5]["FeatureVector"]
Out[] = {22, 42, 0, 2, 2, 2, 6, 6}
```


The list of properties is:
- VertexCount: number of vertexes, also known as [`EventsCount`](Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/EventCounts.md)
- EdgeCount: number of edges, also known as the total number of expressions (except for expressions in the initial and final states). See [Total Element Counts](Documentation/SymbolsAndFunctions/WolframModelAndWolframModelEvolutionObject/Properties/TotalElementCounts.md)
- [VertexConnectivity](https://reference.wolfram.com/language/ref/VertexConnectivity.html): the smallest number of vertices whose deletion from `g` disconnects `g`.
- VertexDegreesQuantiles: The quantiles 0, 0.25, 0.50, 0.75, 1 of the [vertex degrees](https://reference.wolfram.com/language/ref/VertexDegree.html) distribution




This property is useful for applying machine learning to Wolfram Models explorations.



## Example

```wl
In[] := possibileInitsBi = 
  Flatten[Table[{{i, j}, {z, k}}, {i, {0, 1, 2, 3}}, {j, {0, 1, 2, 
      3}}, {z, {0, 1, 2, 3}}, {k, {0, 1, 2, 3}}], 3];

plots = WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, 
        w}}, #, 6, "FinalStatePlot"] & /@ possibileInitsBi;

causalGraph = 
  WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, 
        w}}, #, 6, "CausalGraph"] & /@ possibileInitsBi;

feats = WolframModel[{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, 
       w}}, #, 6, "FeatureVector"] & /@ possibileInitsBi;


FeatureSpacePlot[feats -> plots, LabelingFunction -> Tooltip]

FeatureSpacePlot[feats -> causalGraph, LabelingFunction -> Tooltip]
```
```wl
Out[] = - Graphics -
```



