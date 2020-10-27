###### [Symbols and Functions](/README.md#symbols-and-functions) > [WolframModel and WolframModelEvolutionObject](../WolframModelAndWolframModelEvolutionObject.md) > [Properties](../WolframModelAndWolframModelEvolutionObject.md#properties) >

# Edge and Event Generations

**`"EdgeGenerationsList"`** (aka `"ExpressionGenerations"`) yields the list of generation numbers (numbers of predecessor layers) for each edge in [`"AllEventsEdgesList"`](AllEdgesThroughoutEvolution.md):

```wl
In[] := WolframModel[{{1, 2}, {1, 3}, {1, 4}} ->
  {{2, 2}, {3, 2}, {3, 4}, {3, 5}},
 {{1, 1}, {1, 1}, {1, 1}}, 5, "EdgeGenerationsList"]
Out[] = {0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5,
   5, 5, 5, 5}
```

 **`"AllEventsGenerationsList"`** (aka `"EventGenerations"`) gives the same for events. The generation of an event is defined as the generation of edges it produces as output. Here edges of different generations are colored differently:

```wl
In[] := With[{
  evolution = WolframModel[{{1, 2}, {1, 3}, {1, 4}} ->
     {{2, 2}, {3, 2}, {3, 4}, {3, 5}},
    {{1, 1}, {1, 1}, {1, 1}}, 5]},
 MapThread[
  WolframModelPlot[#, EdgeStyle -> #2] &, {evolution["StatesList"],
   Replace[evolution[
        "EdgeGenerationsList"][[#]] & /@ (evolution[
         "StateEdgeIndicesAfterEvent", #] &) /@
      Prepend[0] @ Accumulate @ evolution["GenerationEventsCountList"],
    g_ :> ColorData["Rainbow"][g/5], {2}]}]]
```

<img src="/Documentation/Images/GenerationColoredStatePlots.png" width="746">

Event and expression generations correspond to layers in [`"LayeredCausalGraph"`](CausalGraphs.md) and [`"ExpressionsEventsGraph"`](CausalGraphs.md):

```wl
In[] := WolframModel[{{1, 2}, {1, 3}, {1, 4}} ->
  {{2, 2}, {3, 2}, {3, 4}, {3, 5}},
 {{1, 1}, {1, 1}, {1, 1}}, 5, "AllEventsGenerationsList"]
Out[] = {1, 2, 3, 4, 5, 5}
```

```wl
In[] := WolframModel[{{1, 2}, {1, 3}, {1, 4}} ->
  {{2, 2}, {3, 2}, {3, 4}, {3, 5}},
 {{1, 1}, {1, 1}, {1, 1}}, 5, "LayeredCausalGraph"]
```

<img src="/Documentation/Images/HypergraphModelLayeredCausalGraph.png" width="218">
